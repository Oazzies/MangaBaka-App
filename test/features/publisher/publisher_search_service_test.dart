import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockHttpClient extends Fake implements http.Client {
  http.Response? response;
  Object? throwOnGet;
  Uri? lastUri;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    lastUri = url;
    if (throwOnGet != null) throw throwOnGet!;
    return response ?? http.Response('{"data": []}', 200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockHttpClient client;
  late PublisherSearchService service;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();

    client = _MockHttpClient();
    service = PublisherSearchService(client: client);
  });

  group('PublisherSearchService.searchPublishers', () {
    test('sends query parameter', () async {
      client.response = http.Response('{"data": []}', 200);
      await service.searchPublishers(query: 'shueisha');
      expect(client.lastUri!.queryParameters['q'], 'shueisha');
      expect(client.lastUri!.queryParameters.containsKey('content_rating'), isFalse);
    });

    test('passes paging and sort params', () async {
      client.response = http.Response('{"data": []}', 200);
      await service.searchPublishers(
        query: 'x',
        page: 2,
        limit: 25,
        sortBy: PublisherSearchService.sortSeriesCountDesc,
      );
      final q = client.lastUri!.queryParameters;
      expect(q['page'], '2');
      expect(q['limit'], '25');
      expect(q['sort_by'], 'series_count_desc');
    });

    test('calls the v2 endpoint', () async {
      await service.searchPublishers();
      expect(client.lastUri!.path, '/v2/publishers');
    });

    test('parses returned publishers', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [
            {'id': 1, 'name': 'A'},
            {'id': 2, 'name': 'B'},
          ],
        }),
        200,
      );
      final results = await service.searchPublishers();
      expect(results.map((p) => p.name), ['A', 'B']);
    });

    test('throws ApiException on non-200 status', () async {
      client.response = http.Response('boom', 500);
      await expectLater(
        service.searchPublishers(),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws NetworkException on http.ClientException', () async {
      client.throwOnGet = http.ClientException('down');
      await expectLater(
        service.searchPublishers(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws NetworkException on TimeoutException', () async {
      client.throwOnGet = TimeoutException('slow');
      await expectLater(
        service.searchPublishers(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ParseException on malformed JSON', () async {
      client.response = http.Response('not-json', 200);
      await expectLater(
        service.searchPublishers(),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('PublisherSearchService.getPublisher', () {
    test('returns Publisher on 200', () async {
      client.response = http.Response(
        jsonEncode({'data': {'id': 99, 'name': 'Shueisha'}}),
        200,
      );
      final p = await service.getPublisher('99');
      expect(client.lastUri!.path, '/v2/publishers/99');
      expect(p.id, '99');
      expect(p.name, 'Shueisha');
    });

    test('throws ApiException on non-200', () async {
      client.response = http.Response('nope', 404);
      await expectLater(
        service.getPublisher('1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('PublisherSearchService.search (params map)', () {
    test('filters out unauthorized keys like content_rating', () async {
      client.response = http.Response('{"data": [], "total": 0}', 200);
      await service.search({'q': 'x', 'content_rating': ['erotica'], 'invalid_param': 'foo'});
      expect(client.lastUri!.queryParameters.containsKey('content_rating'), isFalse);
      expect(client.lastUri!.queryParameters.containsKey('invalid_param'), isFalse);
      expect(client.lastUri!.queryParameters['q'], 'x');
    });

    test('returns total alongside publishers', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [{'id': 1, 'name': 'A'}],
          'total': 42,
        }),
        200,
      );
      final r = await service.search({});
      expect(r.publishers, hasLength(1));
      expect(r.total, 42);
    });

    test('reads the v2 total from pagination.count', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [{'id': 1, 'name': 'A'}],
          'pagination': {'count': 7, 'page': 1, 'limit': 50},
        }),
        200,
      );
      final r = await service.search({});
      expect(r.total, 7);
    });

    test('drops params v2 rejects (type, closed, year bounds)', () async {
      await service.search({'type': 'company', 'closed': true, 'year_lower': 1990});
      expect(client.lastUri!.queryParameters, isEmpty);
    });
  });

  group('PublisherSearchService.getSimilar / getStats', () {
    test('getSimilar parses suggestions from the v2 path', () async {
      client.response = http.Response(
        jsonEncode({
          'data': [
            {'id': 32, 'name': 'Kodansha', 'canonical_url': 'https://x', 'hits': 80, 'score': 0.68},
          ],
        }),
        200,
      );
      final similar = await service.getSimilar('35');
      expect(client.lastUri!.path, '/v2/publishers/35/similar');
      expect(similar.single.id, '32');
      expect(similar.single.hits, 80);
      expect(similar.single.score, closeTo(0.68, 1e-9));
    });

    test('getStats parses distributions and tag shares', () async {
      client.response = http.Response(
        jsonEncode({
          'data': {
            'series_count': 100,
            'tagged_count': 90,
            'has_anime': 5,
            'score': {'average': 66.5},
            'years': {'first': 1949, 'last': 2026},
            'media_type': [{'key': 'manga', 'count': 90}],
            'decades': [{'decade': 1990, 'count': 12}],
            'known_for': [
              {'id': 30, 'name': 'Sports', 'count': 8, 'share': 0.08, 'catalog_share': 0.02},
            ],
            'shares_with': [
              {'id': 36, 'name': 'MANGA Plus', 'shared_count': 4},
            ],
          },
        }),
        200,
      );
      final stats = await service.getStats('35');
      expect(client.lastUri!.path, '/v2/publishers/35/stats');
      expect(stats.seriesCount, 100);
      expect(stats.averageScore, 66.5);
      expect(stats.firstYear, 1949);
      expect(stats.mediaTypes.single.key, 'manga');
      expect(stats.decades.single.key, '1990');
      expect(stats.knownFor.single.lift, closeTo(4, 1e-9));
      expect(stats.sharesWith.single.sharedCount, 4);
    });

    test('getStats fails on a missing data object', () async {
      client.response = http.Response('{"status": 200}', 200);
      await expectLater(service.getStats('1'), throwsA(isA<ParseException>()));
    });
  });
}
