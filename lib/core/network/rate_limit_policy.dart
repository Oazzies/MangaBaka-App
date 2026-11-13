import 'dart:io';

import 'package:http/http.dart' as http;

/// Rate-limit retry and `Retry-After` header parsing policy for [ApiClient].
abstract final class RateLimitPolicy {
  static const Duration baseBackoff = Duration(seconds: 1);
  static const Duration maxBackoff = Duration(seconds: 10);

  /// Returns how long to wait before retrying [response], or `null` when it
  /// should not be retried.
  ///
  /// A 429 is always retryable; a 503 only when the server supplies a usable
  /// `Retry-After` header.
  static Duration? rateLimitWait(http.Response response, int attempt) {
    final status = response.statusCode;
    if (status != 429 && status != 503) return null;
    final retryAfter = parseRetryAfter(response.headers['retry-after']);
    if (status == 503 && retryAfter == null) return null;

    final wait = retryAfter ?? baseBackoff * (1 << attempt);
    if (wait > maxBackoff) return null;
    return wait;
  }

  /// Parses a `Retry-After` header (delta-seconds or HTTP-date).
  /// Returns `null` when absent or unparseable; a past date yields zero.
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
}
