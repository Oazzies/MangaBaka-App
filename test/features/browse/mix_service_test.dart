import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';

class _MockHttpClient extends Fake implements http.Client {
  http.Response? response;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  Object? throwOnGet;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    lastUri = url;
    lastHeaders = headers;
    if (throwOnGet != null) throw throwOnGet!;
    return response ?? http.Response('{"data": [], "dna": []}', 200);
  }
}

void main() {
  late _MockHttpClient client;
  late MixService service;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    client = _MockHttpClient();
    service = MixService(client: client);
  });

  group('MixService.fetchMix', () {
    test('builds query with multiple series ids and limit', () async {
      client.response = http.Response(jsonEncode({'data': [], 'dna': [], 'seed_count': 0}), 200);
      await service.fetchMix(seriesIds: [1, 2, 3], limit: 5);
      expect(client.lastUri, isNotNull);
      expect(client.lastUri!.queryParametersAll['series'], ['1', '2', '3']);
      expect(client.lastUri!.queryParameters['limit'], '5');
    });

    test('passes optional flags when provided', () async {
      client.response = http.Response('{"data": [], "dna": []}', 200);
      await service.fetchMix(
        seriesIds: [1],
        strict: true,
        blendUserId: 'user42',
        excludeUserLibrary: 'user42',
        contentRating: ['safe', 'suggestive'],
      );
      final q = client.lastUri!.queryParametersAll;
      expect(q['strict'], ['true']);
      expect(q['blend_user_id'], ['user42']);
      expect(q['exclude_user_library'], ['user42']);
      expect(q['content_rating'], ['safe', 'suggestive']);
    });

    test('parses dna sorted by weight descending', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [],
          'dna': [
            {'tag_id': 1, 'name': 'a', 'weight': 0.2},
            {'tag_id': 2, 'name': 'b', 'weight': 0.9},
            {'tag_id': 3, 'name': 'c', 'weight': 0.5},
          ],
          'seed_count': 1,
        }),
        200,
      );

      final result = await service.fetchMix(seriesIds: [1]);
      expect(result.dna.map((d) => d.name), ['b', 'c', 'a']);
      expect(result.seedCount, 1);
    });

    test('drops dna entries without a name', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [],
          'dna': [
            {'tag_id': 1, 'name': '', 'weight': 0.5},
            {'tag_id': 2, 'name': 'x', 'weight': 0.4},
          ],
          'seed_count': 0,
        }),
        200,
      );
      final result = await service.fetchMix(seriesIds: [1]);
      expect(result.dna, hasLength(1));
      expect(result.dna.first.name, 'x');
    });

    test('throws on non-200 status', () async {
      client.response = http.Response('boom', 500);
      expect(() => service.fetchMix(seriesIds: [1]), throwsA(isA<Exception>()));
    });

    test('sends User-Agent header', () async {
      client.response = http.Response('{"data": [], "dna": []}', 200);
      await service.fetchMix(seriesIds: [1]);
      expect(client.lastHeaders, containsPair('User-Agent', isA<String>()));
    });
  });

  group('MixService.fetchSeedSuggestions', () {
    test('returns empty list when seed count is below 2', () async {
      final r = await service.fetchSeedSuggestions([1]);
      expect(r, isEmpty);
      expect(client.lastUri, isNull);
    });

    test('returns parsed suggestions on success', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [
            {'series': {'id': 10, 'title': 'A'}},
            {'series': {'id': 11, 'title': 'B'}},
          ],
        }),
        200,
      );
      final r = await service.fetchSeedSuggestions([1, 2]);
      expect(r.map((s) => s.id), [10, 11]);
    });

    test('returns empty list on non-200', () async {
      client.response = http.Response('error', 500);
      final r = await service.fetchSeedSuggestions([1, 2]);
      expect(r, isEmpty);
    });

    test('returns empty list on thrown error', () async {
      client.throwOnGet = Exception('boom');
      final r = await service.fetchSeedSuggestions([1, 2]);
      expect(r, isEmpty);
    });
  });
}
