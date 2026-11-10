import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/network/api_client.dart';

void main() {
  late List<Duration> waits;
  late int calls;

  ApiClient clientFor(
    List<http.Response> responses, {
    int maxRateLimitRetries = 2,
  }) {
    calls = 0;
    return ApiClient(
      client: MockClient((_) async => responses[calls++]),
      maxRateLimitRetries: maxRateLimitRetries,
      delay: (d) async => waits.add(d),
    );
  }

  setUp(() => waits = []);

  final url = Uri.parse('https://x.test/a');

  test('retries a 429 and returns the later success', () async {
    final client = clientFor([
      http.Response('slow down', 429),
      http.Response('ok', 200),
    ]);
    final result = await client.send(url, operation: 'fetch');
    expect(result.body, 'ok');
    expect(calls, 2);
    expect(waits, [const Duration(seconds: 1)]);
  });

  test('backs off exponentially, then surfaces the 429', () async {
    final client = clientFor(List.filled(3, http.Response('no', 429)));
    await expectLater(
      client.send(url, operation: 'fetch'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 429)),
    );
    expect(calls, 3);
    expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
  });

  test('honours Retry-After seconds', () async {
    final client = clientFor([
      http.Response('no', 429, headers: {'retry-after': '3'}),
      http.Response('ok', 200),
    ]);
    await client.send(url, operation: 'fetch');
    expect(waits, [const Duration(seconds: 3)]);
  });

  test('gives up at once when Retry-After exceeds the cap', () async {
    final client = clientFor([
      http.Response('no', 429, headers: {'retry-after': '120'}),
    ]);
    await expectLater(
      client.send(url, operation: 'fetch'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
    expect(waits, isEmpty);
  });

  test('retries a 503 only when it carries Retry-After', () async {
    final bare = clientFor([http.Response('down', 503)]);
    await expectLater(
      bare.send(url, operation: 'fetch'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);

    final told = clientFor([
      http.Response('down', 503, headers: {'retry-after': '1'}),
      http.Response('ok', 200),
    ]);
    expect((await told.send(url, operation: 'fetch')).body, 'ok');
  });

  test('does not retry a 429 the caller accepts', () async {
    final client = clientFor([http.Response('no', 429)]);
    final result = await client.send(
      url,
      operation: 'fetch',
      acceptedStatuses: {200, 429},
    );
    expect(result.statusCode, 429);
    expect(calls, 1);
  });

  test('maxRateLimitRetries: 0 surfaces the first 429', () async {
    final client = clientFor([
      http.Response('no', 429),
    ], maxRateLimitRetries: 0);
    await expectLater(
      client.send(url, operation: 'fetch'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
  });

  test('withContext keeps the retry policy', () async {
    final client = clientFor([
      http.Response('no', 429),
      http.Response('ok', 200),
    ]).withContext('other');
    expect((await client.send(url, operation: 'fetch')).body, 'ok');
  });

  group('parseRetryAfter', () {
    test('reads delta-seconds', () {
      expect(ApiClient.parseRetryAfter(' 5 '), const Duration(seconds: 5));
    });

    test('reads an HTTP-date relative to now', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final later = HttpDate.format(now.add(const Duration(seconds: 4)));
      expect(
        ApiClient.parseRetryAfter(later, now: now),
        const Duration(seconds: 4),
      );
    });

    test('a past date means retry now', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final earlier = HttpDate.format(now.subtract(const Duration(hours: 1)));
      expect(ApiClient.parseRetryAfter(earlier, now: now), Duration.zero);
    });

    test('rejects missing, negative and garbage values', () {
      expect(ApiClient.parseRetryAfter(null), isNull);
      expect(ApiClient.parseRetryAfter('-1'), isNull);
      expect(ApiClient.parseRetryAfter('soon'), isNull);
    });
  });
}
