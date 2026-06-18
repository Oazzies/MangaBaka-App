import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

void main() {
  group('BrowseHelpers.cleanTitle', () {
    test('strips volume suffix', () {
      expect(BrowseHelpers.cleanTitle('My Hero Academia Vol. 1'), 'My Hero Academia');
      expect(BrowseHelpers.cleanTitle('One Piece Volume 100'), 'One Piece');
    });

    test('strips Part and Book suffixes', () {
      expect(BrowseHelpers.cleanTitle('Berserk Part 2'), 'Berserk');
      expect(BrowseHelpers.cleanTitle('Vinland Saga Book 3'), 'Vinland Saga');
    });

    test('strips Deluxe Edition, Omnibus, Box Set, Manga suffixes', () {
      expect(BrowseHelpers.cleanTitle('Naruto (Deluxe Edition)'), 'Naruto');
      expect(BrowseHelpers.cleanTitle('Dragon Ball Omnibus'), 'Dragon Ball');
      expect(BrowseHelpers.cleanTitle('Attack on Titan Box Set'), 'Attack on Titan');
      expect(BrowseHelpers.cleanTitle('Fullmetal Alchemist Manga'), 'Fullmetal Alchemist');
    });

    test('removes trailing colon or dash', () {
      expect(BrowseHelpers.cleanTitle('Chainsaw Man: Vol. 1'), 'Chainsaw Man');
      expect(BrowseHelpers.cleanTitle('Demon Slayer - Volume 3'), 'Demon Slayer');
    });

    test('returns original title if nothing to strip', () {
      expect(BrowseHelpers.cleanTitle('Spy x Family'), 'Spy x Family');
    });

    test('handles empty string', () {
      expect(BrowseHelpers.cleanTitle(''), '');
    });

    test('is case-insensitive', () {
      expect(BrowseHelpers.cleanTitle('Bleach vol. 5'), 'Bleach');
      expect(BrowseHelpers.cleanTitle('Bleach VOLUME 5'), 'Bleach');
    });
  });

  group('BrowseHelpers.convertAutocompleteToSeries', () {
    test('maps id and title correctly', () {
      final result = AutocompleteSeriesResult(
        id: 42,
        title: 'Test Series',
        thumbnailUrl: 'https://example.com/cover.jpg',
      );
      final series = BrowseHelpers.convertAutocompleteToSeries(result);
      expect(series.id, '42');
      expect(series.title, 'Test Series');
      expect(series.coverUrl, 'https://example.com/cover.jpg');
    });

    test('produces empty strings for unused fields', () {
      final result = AutocompleteSeriesResult(id: 1, title: 'T', thumbnailUrl: '');
      final series = BrowseHelpers.convertAutocompleteToSeries(result);
      expect(series.description, '');
      expect(series.authors, isEmpty);
      expect(series.genres, isEmpty);
    });
  });
}
