import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';

void main() {
  group('Series Model', () {
    final mockJson = {
      'id': '123',
      'title': 'Test Manga',
      'native_title': 'テスト漫画',
      'romanized_title': 'Test Manga Romanized',
      'secondary_titles': {
        'en': 'Secondary Title',
      },
      'authors': ['Author 1'],
      'artists': ['Artist 1'],
      'description': 'Description with <br> and <b>HTML</b>',
      'year': 2021,
      'status': 'ongoing',
      'type': 'manga',
      'rating': 4.5,
      'total_chapters': 100,
      'genres': ['Action', 'Adventure'],
      'tags': ['Tag 1'],
      'last_updated_at': '2021-01-01',
    };

    test('an oddly-typed source rating does not fail the whole series', () {
      final series = Series.fromJson({
        ...mockJson,
        'source': {
          'anilist': {'rating_normalized': 80},
          'kitsu': {'rating_normalized': '90'},
          'mal': {'rating_normalized': 'n/a'},
          'broken': 'not a map',
        },
      });

      expect(series.rating, '85.0');
      expect(series.combinedAverage, 85.0);
    });

    test('Series.fromJson parses correctly', () {
      final series = Series.fromJson(mockJson);

      expect(series.id, '123');
      expect(series.title, 'Test Manga');
      expect(series.nativeTitle, 'テスト漫画');
      expect(series.description, 'Description with \n and **HTML**');
      expect(series.genres, contains('Action'));
      expect(series.authors, contains('Author 1'));
    });

    test('getDisplayTitle returns correct title based on language', () {
      final series = Series.fromJson(mockJson);

      expect(series.getDisplayTitle(TitleLanguage.defaultLang), 'Test Manga');
      expect(series.getDisplayTitle(TitleLanguage.native), 'テスト漫画');
      expect(series.getDisplayTitle(TitleLanguage.romanized), 'Test Manga Romanized');
    });

    test('Series.fromJson parses titles array correctly', () {
      final mockJsonWithTitles = {
        'id': '124',
        'titles': [
          {'title': 'The Apothecary Diaries', 'language': 'en', 'is_primary': true},
          {'title': '薬屋のひとりごと', 'language': 'ja', 'is_primary': true},
          {'title': 'Kusuriya no Hitorigoto', 'language': 'ja-ro', 'is_primary': true, 'traits': ['romanized']},
          {'title': 'Alternative Title 1', 'language': 'en', 'is_primary': false},
        ],
        'authors': ['Author 1'],
        'artists': ['Artist 1'],
        'description': 'Description',
        'year': 2021,
        'status': 'ongoing',
        'type': 'manga',
        'rating': 4.5,
        'total_chapters': 100,
        'genres': ['Action'],
        'tags': ['Tag 1'],
        'last_updated_at': '2021-01-01',
      };

      final series = Series.fromJson(mockJsonWithTitles);

      expect(series.id, '124');
      expect(series.title, 'The Apothecary Diaries');
      expect(series.nativeTitle, '薬屋のひとりごと');
      expect(series.romanizedTitle, 'Kusuriya no Hitorigoto');
      expect(series.secondaryTitles, contains('Alternative Title 1'));
      expect(series.secondaryTitles, contains('薬屋のひとりごと'));
      expect(series.secondaryTitles, contains('Kusuriya no Hitorigoto'));
      expect(series.secondaryTitles, isNot(contains('The Apothecary Diaries')));
    });
  });
}
