import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_autocomplete_service.dart';

LibraryEntry _entry({
  required String id,
  required String title,
  String nativeTitle = '',
  String romanizedTitle = '',
  List<String> secondaryTitles = const [],
  String year = '',
  String type = '',
  String coverUrl = '',
  List<String> genres = const [],
}) {
  return LibraryEntry.fromJson({
    'id': id,
    'state': 'reading',
    'series': {
      'id': id,
      'title': title,
      'native_title': nativeTitle,
      'romanized_title': romanizedTitle,
      'secondary_titles': secondaryTitles.isEmpty
          ? {}
          : {'en': secondaryTitles.map((t) => {'title': t}).toList()},
      'cover': coverUrl.isEmpty
          ? null
          : {
              'x350': {'x1': coverUrl},
              'raw': {'url': coverUrl},
            },
      'authors': [],
      'artists': [],
      'description': '',
      'year': year,
      'status': '',
      'is_licensed': false,
      'has_anime': false,
      'content_rating': 'safe',
      'type': type,
      'rating': '',
      'final_volume': '',
      'total_chapters': '',
      'links': [],
      'publishers': [],
      'genres': genres,
      'tags': [],
      'last_updated_at': '',
    }
  });
}

void main() {
  late LibraryAutocompleteService service;

  setUp(() => service = LibraryAutocompleteService());

  group('LibraryAutocompleteService', () {
    test('returns empty list for empty query', () {
      final results = service.search('', [_entry(id: '1', title: 'Naruto')]);
      expect(results, isEmpty);
    });

    test('returns empty list for whitespace-only query', () {
      final results = service.search('   ', [_entry(id: '1', title: 'Naruto')]);
      expect(results, isEmpty);
    });

    test('title-prefix matches outrank contains matches', () {
      final entries = [
        _entry(id: '1', title: 'Berserk'),
        _entry(id: '2', title: 'Bleach'),
        _entry(id: '3', title: 'My Hero Academia'),
      ];
      final results = service.search('B', entries);
      // Title-prefix matches tie at score 100, so shorter title wins:
      // 'Bleach' (6) before 'Berserk' (7); 'My Hero Academia' is excluded (no prefix/contains 'B').
      expect(results.map((r) => r.title), ['Bleach', 'Berserk']);
    });

    test('native title prefix scores lower than primary title prefix', () {
      final entries = [
        _entry(id: '1', title: 'Other', nativeTitle: 'Naruto'),
        _entry(id: '2', title: 'Naruto'),
      ];
      final results = service.search('Naruto', entries);
      expect(results.first.title, 'Naruto');
    });

    test('shorter title wins tie on equal score', () {
      final entries = [
        _entry(id: '1', title: 'One Piece Stampede'),
        _entry(id: '2', title: 'One Piece'),
      ];
      final results = service.search('One', entries);
      expect(results.first.title, 'One Piece');
    });

    test('non-matching entries are excluded', () {
      final entries = [
        _entry(id: '1', title: 'Naruto'),
        _entry(id: '2', title: 'Bleach'),
      ];
      final results = service.search('Naru', entries);
      expect(results, hasLength(1));
      expect(results.first.title, 'Naruto');
    });

    test('caps to maxResults', () {
      final entries = List.generate(20, (i) => _entry(id: '$i', title: 'Manga $i'));
      final results = service.search('Manga', entries);
      expect(results, hasLength(LibraryAutocompleteService.maxResults));
    });

    test('returned result includes derived fields (id parsed, year, genres trimmed)', () {
      final entries = [
        _entry(
          id: '42',
          title: 'Naruto',
          year: '1999',
          type: 'manga',
          coverUrl: 'cover.png',
          genres: ['action', 'shounen', 'adventure', 'fantasy'],
        ),
      ];
      final results = service.search('Naruto', entries);
      expect(results, hasLength(1));
      expect(results.first.id, 42);
      expect(results.first.year, 1999);
      expect(results.first.type, 'manga');
      expect(results.first.thumbnailUrl, 'cover.png');
      expect(results.first.genres, ['action', 'shounen', 'adventure']);
    });

    test('id falls back to 0 when not parseable', () {
      final entries = [_entry(id: 'abc', title: 'Naruto')];
      final results = service.search('Naru', entries);
      expect(results.first.id, 0);
    });

    test('substring match on secondary titles scores below containing primary match', () {
      final entries = [
        _entry(id: '1', title: 'Naruto Shippuden'),
        _entry(id: '2', title: 'Different', secondaryTitles: ['Sub Naruto']),
      ];
      final results = service.search('Naruto', entries);
      expect(results.first.title, 'Naruto Shippuden');
    });

    test('matches queries ignoring apostrophes, punctuation, and macrons', () {
      final entries = [
        _entry(id: '1', title: "Komi Can't Communicate"),
        _entry(id: '2', title: 'Kaguya-sama: Love Is War'),
        _entry(id: '3', title: 'Yū Yū Hakusho'),
      ];

      expect(
        service.search('komi cant', entries).map((r) => r.title),
        ["Komi Can't Communicate"],
      );
      expect(
        service.search('kaguya sama', entries).map((r) => r.title),
        ['Kaguya-sama: Love Is War'],
      );
      expect(
        service.search('yu yu', entries).map((r) => r.title),
        ['Yū Yū Hakusho'],
      );
    });
  });
}
