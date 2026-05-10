import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/news/models/news.dart';

void main() {
  group('News', () {
    test('fromJson parses correctly and maps sources', () {
      final json = {
        'id': '1',
        'title': 'Test News',
        'url': 'http://test.com',
        'author': 'Tester',
        'source_name': 'ann',
        'published_at': '2021-01-01',
        'series': [],
      };

      final news = News.fromJson(json);

      expect(news.id, '1');
      expect(news.title, 'Test News');
      expect(news.source, 'Anime News Network');
    });

    test('fromJson handles missing source_name', () {
      final json = {
        'id': '1',
        'title': 'Test News',
        'url': 'http://test.com',
        'author': 'Tester',
        'published_at': '2021-01-01',
        'series': [],
      };

      final news = News.fromJson(json);

      expect(news.source, '');
    });
  });
}
