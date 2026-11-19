import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

void main() {
  group('AutocompleteSeriesResult', () {
    test('fromJson parses primary title and ids', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 42,
        'title': 'Naruto',
        'type': 'manga',
      });
      expect(r.id, 42);
      expect(r.title, 'Naruto');
      expect(r.type, 'manga');
      expect(r.allTitles, contains('Naruto'));
    });

    test('fromJson parses id as string', () {
      final r = AutocompleteSeriesResult.fromJson({'id': '7'});
      expect(r.id, 7);
    });

    test('fromJson falls back to the unknown title string when missing', () {
      final r = AutocompleteSeriesResult.fromJson({'id': 1});
      expect(r.title, LocalizationService().translate('unknown_title'));
    });

    test('fromJson collects native + romanized in allTitles', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'title': 'Naruto',
        'native_title': 'ナルト',
        'romanized_title': 'naruto',
      });
      expect(r.allTitles, containsAll(['Naruto', 'ナルト', 'naruto']));
    });

    test('fromJson prefers x150 cover, then x350', () {
      final withX150 = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'cover': {
          'x150': {'x1': 'small.png'},
          'x350': {'x1': 'med.png'},
        },
      });
      expect(withX150.thumbnailUrl, 'small.png');

      final onlyX350 = AutocompleteSeriesResult.fromJson({
        'id': 2,
        'cover': {'x350': {'x1': 'med.png'}},
      });
      expect(onlyX350.thumbnailUrl, 'med.png');
    });

    test('fromJson clamps genres to first three', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'genres': ['a', 'b', 'c', 'd', 'e'],
      });
      expect(r.genres, ['a', 'b', 'c']);
    });

    test('fromJson extracts year from published.start_date', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'published': {'start_date': '1999-09-21'},
      });
      expect(r.year, 1999);
    });

    test('fromJson falls back to year field', () {
      final r = AutocompleteSeriesResult.fromJson({'id': 1, 'year': 2010});
      expect(r.year, 2010);
    });

    test('fromJson deduplicates allTitles', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'title': 'X',
        'titles': [{'title': 'X', 'language': 'en'}],
      });
      expect(r.allTitles.where((t) => t == 'X').length, 1);
    });

    test('fromJson parses and prioritizes titles array', () {
      final r = AutocompleteSeriesResult.fromJson({
        'id': 1,
        'title': 'Legacy Title',
        'titles': [
          {'title': 'Primary English Title', 'language': 'en', 'is_primary': true},
          {'title': 'Alternative Title', 'language': 'ja', 'is_primary': false},
        ],
      });
      expect(r.title, 'Primary English Title');
      expect(r.allTitles, containsAll(['Primary English Title', 'Alternative Title']));
    });

    test('equality is based on id only', () {
      const a = AutocompleteSeriesResult(id: 1, title: 'A', thumbnailUrl: '');
      const b = AutocompleteSeriesResult(id: 1, title: 'Different', thumbnailUrl: '');
      const c = AutocompleteSeriesResult(id: 2, title: 'A', thumbnailUrl: '');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });

    test('fromLibraryData copies inputs verbatim', () {
      final r = AutocompleteSeriesResult.fromLibraryData(
        id: 9,
        title: 'Local',
        thumbnailUrl: 'thumb',
        type: 'manga',
        year: 2020,
        genres: ['x'],
        allTitles: ['Local'],
      );
      expect(r.id, 9);
      expect(r.title, 'Local');
      expect(r.thumbnailUrl, 'thumb');
      expect(r.type, 'manga');
      expect(r.year, 2020);
      expect(r.genres, ['x']);
      expect(r.allTitles, ['Local']);
    });
  });
}
