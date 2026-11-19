import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/network/rate_limit_policy.dart';
import 'package:mangabaka_app/core/utils/uri_utils.dart';
import 'package:mangabaka_app/core/network/api_result.dart';

export 'package:mangabaka_app/core/network/api_result.dart';

/// GET only, so a rate-limit retry can never duplicate a write.
class ApiClient {
  /// Null skips health reporting: the probe itself and non-MangaBaka hosts.
  final String? healthContext;

  final int maxRateLimitRetries;

  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;
  final Future<void> Function(Duration) _delay;

  static final _logger = LoggingService.logger;

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

  /// Closing the derived client leaves the shared pool open.
  ApiClient withContext(String context) => ApiClient._shared(
    healthContext: context,
    client: _client,
    timeout: _timeout,
    maxRateLimitRetries: maxRateLimitRetries,
    delay: _delay,
  );

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
        // No body in the log: logs get shared and bodies can echo user data.
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

  @visibleForTesting
  static Duration? rateLimitWait(http.Response response, int attempt) =>
      RateLimitPolicy.rateLimitWait(response, attempt);

  @visibleForTesting
  static Duration? parseRetryAfter(String? value, {DateTime? now}) =>
      RateLimitPolicy.parseRetryAfter(value, now: now);

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

  void close() {
    if (_ownsClient) _client.close();
  }
}
