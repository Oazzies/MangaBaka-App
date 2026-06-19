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

    test('passes optional filter params', () async {
      client.response = http.Response('{"data": []}', 200);
      await service.searchPublishers(
        query: 'x',
        type: 'company',
        closed: false,
        yearLower: 1990,
        yearUpper: 2020,
        page: 2,
        limit: 25,
        sortBy: 'name',
      );
      final q = client.lastUri!.queryParameters;
      expect(q['type'], 'company');
      expect(q['closed'], 'false');
      expect(q['year_lower'], '1990');
      expect(q['year_upper'], '2020');
      expect(q['page'], '2');
      expect(q['limit'], '25');
      expect(q['sort_by'], 'name');
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

  group('PublisherSearchService.getPublisherFull', () {
    test('returns Publisher on 200', () async {
      client.response = http.Response(
        jsonEncode({'data': {'id': 99, 'name': 'Shueisha'}}),
        200,
      );
      final p = await service.getPublisherFull('99');
      expect(p.id, '99');
      expect(p.name, 'Shueisha');
    });

    test('throws ApiException on non-200', () async {
      client.response = http.Response('nope', 404);
      await expectLater(
        service.getPublisherFull('1'),
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
  });
}
