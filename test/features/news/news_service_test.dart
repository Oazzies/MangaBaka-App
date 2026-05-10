import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
  });

  group('NewsService', () {
    test('getCachedNews returns entries from SharedPreferences', () async {
      final newsData = {
        'data': [
          {
            'id': '1',
            'title': 'Test Title',
            'url': 'http://test.com',
            'author': 'Author',
            'source_name': 'ann',
            'published_at': '2021-01-01',
            'series': [],
          }
        ]
      };
      
      SharedPreferences.setMockInitialValues({
        'mangabaka_app_news_cache': jsonEncode(newsData),
      });

      final service = NewsService();
      final news = await service.getCachedNews();

      expect(news.length, 1);
      expect(news[0].title, 'Test Title');
    });

    test('getCachedNews returns empty list if no cache', () async {
      SharedPreferences.setMockInitialValues({});

      final service = NewsService();
      final news = await service.getCachedNews();

      expect(news, isEmpty);
    });
  });
}
