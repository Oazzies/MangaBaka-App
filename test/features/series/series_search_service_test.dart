import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Fake implements http.Client {
  http.Response? response;
  Uri? lastUri;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    lastUri = url;
    if (response != null) return response!;
    return http.Response('{"data": []}', 200);
  }
}

class FakeMetadataService extends Fake implements MetadataService {
  @override
  bool isInitialized = true;
  @override
  List<Map<String, dynamic>> genres = [{'id': '1', 'name': 'Action'}];
  @override
  List<Map<String, dynamic>> tags = [{'id': '2', 'name': 'Magic'}];
}

class FakeSeriesService extends Fake implements SeriesService {
  int precacheCount = 0;
  @override
  void precacheSeries(dynamic series) {
    precacheCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SeriesSearchService service;
  late MockHttpClient mockClient;
  late FakeSeriesService fakeSeriesService;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<MetadataService>(FakeMetadataService());
    fakeSeriesService = FakeSeriesService();
    getIt.registerSingleton<SeriesService>(fakeSeriesService);
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    SharedPreferences.setMockInitialValues({});
    await SettingsManager().init();
    
    mockClient = MockHttpClient();
    service = SeriesSearchService(client: mockClient);
  });

  group('SeriesSearchService', () {
    test('searchSeriesByName sends correct request and parses response', () async {
      mockClient.response = http.Response(jsonEncode({
        'data': [
          {
            'id': '123',
            'title': 'Test Manga',
            'state': 'safe',
            'native_title': 'N',
            'romanized_title': 'R',
            'cover_url': 'C',
            'authors': [],
            'artists': [],
            'description': 'D',
            'year': '2021',
            'status': 'S',
            'is_licensed': 'false',
            'has_anime': 'false',
            'content_rating': 'safe',
            'type': 'manga',
            'rating': '5',
            'final_volume': '',
            'total_chapters': '10',
            'links': [],
            'publishers': [],
            'genres': [],
            'tags': [],
            'last_updated_at': '2021-01-01',
          }
        ]
      }), 200);

      final results = await service.searchSeriesByName('one piece');

      expect(results, hasLength(1));
      expect(results[0].id, '123');
      expect(results[0].title, 'Test Manga');
      expect(mockClient.lastUri.toString(), contains('q=one+piece'));
      expect(fakeSeriesService.precacheCount, 1);
    });

    test('searchSeriesByName handles API errors', () async {
      mockClient.response = http.Response('Error', 500);

      expect(
        () => service.searchSeriesByName('test'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
