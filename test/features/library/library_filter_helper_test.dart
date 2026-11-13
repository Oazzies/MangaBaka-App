import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

void main() {
  group('LibraryFilterHelper', () {
    final mockSeries = Series(
      id: '1',
      title: 'One Piece',
      state: 'reading',
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: [],
      coverUrl: '',
      rawCoverUrl: '',
      authors: [],
      artists: [],
      description: '',
      year: '1997',
      status: 'ongoing',
      isLicensed: 'yes',
      hasAnime: 'yes',
      contentRating: 'safe',
      type: 'manga',
      rating: '95',
      finalVolume: '',
      totalChapters: '1000',
      links: [],
      publishers: [],
      genres: ['Action', 'Adventure'],
      tags: [],
      lastUpdated: '',
    );

    final mockEntry = LibraryEntry(
      id: '1',
      state: 'reading',
      rating: 10,
      series: mockSeries,
    );

    test('filters by query correctly', () {
      final helper = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: 'Piece',
        contentPreferences: ['safe'],
      );

      final result = helper.getFilteredAndSorted();
      expect(result, hasLength(1));

      final helperNoMatch = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: 'Naruto',
        contentPreferences: ['safe'],
      );
      expect(helperNoMatch.getFilteredAndSorted(), isEmpty);
    });

    test('filters by tab (state) correctly', () {
      final helper = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: '',
        contentPreferences: ['safe'],
      );

      expect(helper.getByTab('reading'), hasLength(1));
      expect(helper.getByTab('completed'), isEmpty);
    });

    test('filters by content rating correctly', () {
      final helper = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: '',
        contentPreferences: ['erotica'], // Only erotica
      );

      expect(helper.getFilteredAndSorted(), isEmpty);
    });

    test('filters by status correctly using SearchFilters', () {
      final helper = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: '',
        contentPreferences: ['safe'],
        filters: SearchFilters(status: ['ongoing']),
      );

      expect(helper.getFilteredAndSorted(), hasLength(1));

      final helperNoMatch = LibraryFilterHelper(
        allEntries: [mockEntry],
        query: '',
        contentPreferences: ['safe'],
        filters: SearchFilters(status: ['completed']),
      );
      expect(helperNoMatch.getFilteredAndSorted(), isEmpty);
    });

    test('matches apostrophes, punctuation, diacritics, and secondary titles', () {
      final komiSeries = Series(
        id: '2',
        title: "Komi Can't Communicate",
        state: 'reading',
        nativeTitle: '古見さんは、コミュ症です。',
        romanizedTitle: 'Komi-san wa, Komyushō desu.',
        secondaryTitles: ['Komi-san wa, Komyushou desu.'],
        coverUrl: '',
        rawCoverUrl: '',
        authors: [],
        artists: [],
        description: '',
        year: '2016',
        status: 'completed',
        isLicensed: 'yes',
        hasAnime: 'yes',
        contentRating: 'safe',
        type: 'manga',
        rating: '90',
        finalVolume: '',
        totalChapters: '500',
        links: [],
        publishers: [],
        genres: [],
        tags: [],
        lastUpdated: '',
      );
      final komiEntry = LibraryEntry(
        id: '2',
        state: 'reading',
        rating: 9,
        series: komiSeries,
      );

      for (final q in [
        'komi cant',
        "komi can’t",
        'komi communicate',
        'komyusho',
        'komi san',
        'komyushou',
      ]) {
        final helper = LibraryFilterHelper(
          allEntries: [komiEntry],
          query: q,
          contentPreferences: ['safe'],
        );
        expect(
          helper.getFilteredAndSorted(),
          hasLength(1),
          reason: 'Expected "$q" to match Komi entry',
        );
      }
    });
  });
}
