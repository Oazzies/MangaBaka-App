import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/utils/uri_utils.dart';

/// The single place where an HTTP call to a MangaBaka backend is made.
///
/// Every service used to repeat the same block around `http.get`: attach the
/// User-Agent, apply the network timeout, report the outcome to
/// [BackendHealthService], branch on the status code, decode the body, and
/// translate several transport failure modes into the app's [AppException]
/// hierarchy. That boilerplate had drifted — most services skipped the health
/// report entirely, so an outage reached through them without the banner ever
/// appearing — and it accounted for much of the length of the service files.
///
/// The exception types thrown here are deliberately identical to the ones the
/// hand-written blocks threw, so existing `catch` clauses at call sites keep
/// working unchanged:
///
/// * [NetworkException] — transport failure or timeout (`NETWORK_ERROR` /
///   `TIMEOUT`).
/// * [ApiException] — a response arrived but its status was not accepted.
/// * [ParseException] — the body was not the JSON shape the caller expected.
/// * [AppError] — anything else, so no bug escapes as a raw error.
class ApiClient {
  /// Label this client's requests report under in [BackendHealthService].
  ///
  /// A null context opts out of health reporting entirely — used by the health
  /// probe itself and by non-MangaBaka hosts (e.g. the GitHub releases feed),
  /// whose availability says nothing about the MangaBaka backend.
  final String? healthContext;

  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  static final _logger = LoggingService.logger;

  ApiClient({
    this.healthContext,
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _timeout = timeout ??
            const Duration(seconds: AppConstants.networkTimeoutSeconds);

  ApiClient._shared({
    required this.healthContext,
    required http.Client client,
    required Duration timeout,
  })  : _client = client,
        _ownsClient = false,
        _timeout = timeout;

  /// Derives a client sharing this one's connection pool but reporting under a
  /// different [context]. Closing the derived client leaves the pool open.
  ApiClient withContext(String context) => ApiClient._shared(
        healthContext: context,
        client: _client,
        timeout: _timeout,
      );

  /// Builds a request URI from [base] and [params], dropping null and empty
  /// values and stringifying the rest (lists become repeated parameters).
  static Uri uri(String base, [Map<String, dynamic>? params]) {
    final parsed = Uri.parse(base);
    if (params == null || params.isEmpty) return parsed;

    final cleaned = <String, dynamic>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is Iterable) {
        final list = value.toList();
        if (list.isEmpty) return;
        cleaned[key] = list;
        return;
      }
      cleaned[key] = value;
    });
    if (cleaned.isEmpty) return parsed;

    return parsed.replace(
      queryParameters: UriUtils.encodeQueryParameters(cleaned),
    );
  }

  /// Performs a GET and hands the decoded JSON body to [parse].
  ///
  /// [operation] names the call in log lines and error messages (e.g.
  /// `'search series'`). [acceptedStatuses] lets a caller treat a non-200 as
  /// success — pass `{200, 404}` when a missing resource is an expected
  /// outcome rather than a failure, and branch on [ApiResult.statusCode] via
  /// [send] if the distinction matters.
  Future<T> getJson<T>(
    Uri url, {
    required String operation,
    required T Function(dynamic json) parse,
    Map<String, String>? headers,
    Set<int> acceptedStatuses = const {200},
    Duration? timeout,
  }) async {
    final result = await send(
      url,
      operation: operation,
      headers: headers,
      acceptedStatuses: acceptedStatuses,
      timeout: timeout,
    );
    return decode(result.body, operation: operation, parse: parse);
  }

  /// Performs a GET and returns the raw body, having applied the timeout,
  /// health reporting and status check.
  Future<ApiResult> send(
    Uri url, {
    required String operation,
    Map<String, String>? headers,
    Set<int> acceptedStatuses = const {200},
    Duration? timeout,
  }) async {
    _logger.info('$operation: GET $url');
    try {
      final response = await _client
          .get(url, headers: _headersFor(headers))
          .timeout(
            timeout ?? _timeout,
            onTimeout: () => throw TimeoutException('$operation timed out'),
          );

      _logger.fine('$operation: status ${response.statusCode}');
      _report(
        ok: !isServerErrorStatus(response.statusCode),
        statusCode: response.statusCode,
      );

      if (!acceptedStatuses.contains(response.statusCode)) {
        // The body stays out of the log: logs are exported and shared, and
        // an error body can echo back user data. It is kept on the exception.
        _logger.severe('$operation failed. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to $operation',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'REQUEST_FAILED',
        );
      }
      return ApiResult(statusCode: response.statusCode, body: response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout during $operation', e, st);
      _report(ok: false, error: 'timeout');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error during $operation', e, st);
      _report(ok: false, error: e);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on HandshakeException catch (e, st) {
      _logger.severe('TLS handshake failed during $operation', e, st);
      _report(ok: false, error: e);
      throw NetworkException(
        message: 'Could not establish a secure connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error during $operation', e, st);
      _report(ok: false, error: e);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } catch (e, st) {
      _logger.severe('Unexpected error during $operation', e, st);
      _report(ok: false, error: e);
      throw AppError(
        message: 'An unexpected error occurred while trying to $operation',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Decodes [body] and runs [parse] over it, converting any failure into a
  /// [ParseException] naming the [operation], so a malformed payload never
  /// surfaces to the UI as a bare `FormatException` or cast error.
  static T decode<T>(
    String body, {
    required String operation,
    required T Function(dynamic json) parse,
  }) {
    try {
      return parse(jsonDecode(body));
    } catch (e, st) {
      _logger.severe('Failed to parse $operation response', e, st);
      throw ParseException(
        message: 'Failed to parse $operation response',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Map<String, String> _headersFor(Map<String, String>? extra) => {
        'User-Agent': AppConstants.userAgent,
        if (extra != null) ...extra,
      };

  void _report({required bool ok, int? statusCode, Object? error}) {
    final context = healthContext;
    if (context == null) return;
    reportApiOutcome(
      ok: ok,
      context: context,
      statusCode: statusCode,
      error: error,
    );
  }

  /// Releases the underlying connection pool. A no-op when the client was
  /// handed a caller-owned [http.Client] (including clients from
  /// [withContext]) — closing someone else's client would break it.
  void close() {
    if (_ownsClient) _client.close();
  }
}

/// A response that passed the status check, ready to be decoded.
class ApiResult {
  final int statusCode;
  final String body;

  const ApiResult({required this.statusCode, required this.body});
}
