import 'dart:io';

import 'package:http/http.dart' as http;

abstract final class RateLimitPolicy {
  static const Duration baseBackoff = Duration(seconds: 1);
  static const Duration maxBackoff = Duration(seconds: 10);

  static Duration? rateLimitWait(http.Response response, int attempt) {
    final status = response.statusCode;
    if (status != 429 && status != 503) return null;
    final retryAfter = parseRetryAfter(response.headers['retry-after']);
    if (status == 503 && retryAfter == null) return null;

    final wait = retryAfter ?? baseBackoff * (1 << attempt);
    if (wait > maxBackoff) return null;
    return wait;
  }

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
