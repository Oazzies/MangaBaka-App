import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
///
/// Rate limiting: a 429 (or a 503 carrying `Retry-After`) is retried up to
/// [maxRateLimitRetries] times, honouring the server's `Retry-After` when it
/// is sane and falling back to exponential backoff otherwise. Only GETs go
/// through this client, so a retry can never duplicate a write.
class ApiClient {
  /// Label this client's requests report under in [BackendHealthService].
  ///
  /// A null context opts out of health reporting entirely — used by the health
  /// probe itself and by non-MangaBaka hosts (e.g. the GitHub releases feed),
  /// whose availability says nothing about the MangaBaka backend.
  final String? healthContext;

  /// How many times a rate-limited request is retried before the 429 is
  /// surfaced as an [ApiException]. Zero disables retrying — for callers that
  /// run their own backoff and must see the first 429.
  final int maxRateLimitRetries;

  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;
  final Future<void> Function(Duration) _delay;

  static final _logger = LoggingService.logger;

  /// First fallback wait when the server gives no usable `Retry-After`;
  /// doubles on each further attempt.
  static const Duration _baseBackoff = Duration(seconds: 1);

  /// Upper bound on any single wait. A `Retry-After` beyond this means the
  /// quota is exhausted for a while — failing fast beats a frozen screen.
  static const Duration _maxBackoff = Duration(seconds: 10);

  /// Creates a client.
  ///
  /// [delay] exists for tests, which pass a no-op so retries run instantly.
  ApiClient({
    this.healthContext,
    http.Client? client,
    Duration? timeout,
    this.maxRateLimitRetries = 2,
    Future<void> Function(Duration)? delay,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _timeout =
           timeout ??
           const Duration(seconds: AppConstants.networkTimeoutSeconds),
       _delay = delay ?? Future<void>.delayed;

  ApiClient._shared({
    required this.healthContext,
    required http.Client client,
    required Duration timeout,
    required this.maxRateLimitRetries,
    required Future<void> Function(Duration) delay,
  }) : _client = client,
       _ownsClient = false,
       _timeout = timeout,
       _delay = delay;

  /// Derives a client sharing this one's connection pool but reporting under a
  /// different [context]. Closing the derived client leaves the pool open.
  ApiClient withContext(String context) => ApiClient._shared(
    healthContext: context,
    client: _client,
    timeout: _timeout,
    maxRateLimitRetries: maxRateLimitRetries,
    delay: _delay,
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
  /// rate-limit retries, health reporting and status check.
  Future<ApiResult> send(
    Uri url, {
    required String operation,
    Map<String, String>? headers,
    Set<int> acceptedStatuses = const {200},
    Duration? timeout,
  }) async {
    _logger.info('$operation: GET $url');
    try {
      var response = await _get(url, operation, headers, timeout);

      for (var attempt = 0; attempt < maxRateLimitRetries; attempt++) {
        // A caller that accepts the status wants to see it, not a retry.
        if (acceptedStatuses.contains(response.statusCode)) break;
        final wait = rateLimitWait(response, attempt);
        if (wait == null) break;
        _logger.warning(
          '$operation: HTTP ${response.statusCode}, retry ${attempt + 1}/'
          '$maxRateLimitRetries in ${wait.inMilliseconds}ms',
        );
        await _delay(wait);
        response = await _get(url, operation, headers, timeout);
      }

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

  Future<http.Response> _get(
    Uri url,
    String operation,
    Map<String, String>? headers,
    Duration? timeout,
  ) => _client
      .get(url, headers: _headersFor(headers))
      .timeout(
        timeout ?? _timeout,
        onTimeout: () => throw TimeoutException('$operation timed out'),
      );

  /// How long to wait before retrying [response], or null when it should not
  /// be retried.
  ///
  /// A 429 is always retryable; a 503 only when the server says when to come
  /// back — a bare 503 is an outage, which the health banner handles.
  @visibleForTesting
  static Duration? rateLimitWait(http.Response response, int attempt) {
    final status = response.statusCode;
    if (status != 429 && status != 503) return null;
    final retryAfter = parseRetryAfter(response.headers['retry-after']);
    if (status == 503 && retryAfter == null) return null;

    final wait = retryAfter ?? _baseBackoff * (1 << attempt);
    // Past the cap the quota is gone for a while; give up rather than stall.
    if (wait > _maxBackoff) return null;
    return wait;
  }

  /// Parses a `Retry-After` header: delta-seconds or an HTTP-date.
  /// Returns null when absent or unparseable; a past date yields zero.
  @visibleForTesting
  static Duration? parseRetryAfter(String? value, {DateTime? now}) {
    if (value == null) return null;
    final trimmed = value.trim();
    final seconds = int.tryParse(trimmed);
    if (seconds != null) {
      return seconds < 0 ? null : Duration(seconds: seconds);
    }
    try {
      final at = HttpDate.parse(trimmed);
      final delta = at.difference(now ?? DateTime.now().toUtc());
      return delta.isNegative ? Duration.zero : delta;
    } on HttpException {
      return null;
    } on FormatException {
      return null;
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
