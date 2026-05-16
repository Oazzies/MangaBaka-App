import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/screens/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/services/state_normalizer.dart';

class LibraryFilterHelper {
  final List<LibraryEntry> allEntries;
  final String query;
  final List<String> contentPreferences;
  final SearchFilters? filters;

  LibraryFilterHelper({
    required this.allEntries,
    required this.query,
    required this.contentPreferences,
    this.filters,
  });

  List<LibraryEntry>? _cachedFiltered;

  List<LibraryEntry> getFilteredAndSorted() {
    if (_cachedFiltered != null) return _cachedFiltered!;

    List<LibraryEntry> filtered = allEntries.where((entry) {
      // 1. Query Search
      final matchesQuery = query.isEmpty ||
          entry.series.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.series.nativeTitle.toLowerCase().contains(query.toLowerCase()) ||
          entry.series.romanizedTitle.toLowerCase().contains(query.toLowerCase());
      if (!matchesQuery) return false;

      // 2. Content Rating (Settings)
      final matchesRating = contentPreferences.isEmpty ||
          contentPreferences.contains(entry.series.contentRating.toLowerCase());
      if (!matchesRating) return false;

      if (filters != null) {
        final f = filters!;

        // 3. Series Type
        if (f.type.isNotEmpty && !f.type.contains(entry.series.type.toLowerCase())) return false;
        if (f.typeNot.isNotEmpty && f.typeNot.contains(entry.series.type.toLowerCase())) return false;

        // 4. Series Status
        if (f.status.isNotEmpty && !f.status.contains(entry.series.status.toLowerCase())) return false;
        if (f.statusNot.isNotEmpty && f.statusNot.contains(entry.series.status.toLowerCase())) return false;

        // 5. Genres
        if (f.genre.isNotEmpty) {
          final entryGenres = entry.series.genres.map((g) => g.toLowerCase()).toSet();
          if (!f.genre.every((g) => entryGenres.contains(g.toLowerCase()))) return false;
        }
        if (f.genreNot.isNotEmpty) {
          final entryGenres = entry.series.genres.map((g) => g.toLowerCase()).toSet();
          if (f.genreNot.any((g) => entryGenres.contains(g.toLowerCase()))) return false;
        }

        // 5b. Tags
        if (f.tag.isNotEmpty) {
          final entryTags = entry.series.tags.map((t) => t.toLowerCase()).toSet();
          if (f.tagMode == 'and') {
            if (!f.tag.every((t) => entryTags.contains(t.toLowerCase()))) return false;
          } else {
            if (!f.tag.any((t) => entryTags.contains(t.toLowerCase()))) return false;
          }
        }
        if (f.tagNot.isNotEmpty) {
          final entryTags = entry.series.tags.map((t) => t.toLowerCase()).toSet();
          if (f.tagNot.any((t) => entryTags.contains(t.toLowerCase()))) return false;
        }

        // 6. Rating (0-100)
        final seriesRating = double.tryParse(entry.series.rating) ?? 0.0;
        if (seriesRating < f.ratingLower || seriesRating > f.ratingUpper) return false;

        // 7. Year
        if (f.publishedYearLower != null || f.publishedYearUpper != null) {
          final seriesYear = int.tryParse(entry.series.year);
          if (seriesYear != null) {
            if (f.publishedYearLower != null && seriesYear < f.publishedYearLower!) return false;
            if (f.publishedYearUpper != null && seriesYear > f.publishedYearUpper!) return false;
          } else if (f.publishedYearLower != null || f.publishedYearUpper != null) {
            return false;
          }
        }

        // 7b. Licensed Status
        if (f.isLicensed != null) {
          final isLicensed = entry.series.isLicensed.toLowerCase() == 'yes' ||
              entry.series.isLicensed == '1' ||
              entry.series.isLicensed.toLowerCase() == 'true';
          if (f.isLicensed != isLicensed) return false;
        }
      }

      return true;
    }).toList();

    // 8. Sorting
    if (filters?.sortBy != null && filters!.sortBy!.isNotEmpty) {
      final sortBy = filters!.sortBy!;
      if (sortBy == 'random') {
        filtered.shuffle();
      } else {
        filtered.sort((a, b) {
          switch (sortBy) {
            case 'name_asc':
              return a.series.title.compareTo(b.series.title);
            case 'name_desc':
              return b.series.title.compareTo(a.series.title);
            case 'popularity_desc':
            case 'rating_desc':
              final ra = double.tryParse(a.series.rating) ?? 0.0;
              final rb = double.tryParse(b.series.rating) ?? 0.0;
              return rb.compareTo(ra);
            case 'popularity_asc':
            case 'rating_asc':
              final ra = double.tryParse(a.series.rating) ?? 0.0;
              final rb = double.tryParse(b.series.rating) ?? 0.0;
              return ra.compareTo(rb);
            case 'last_updated':
              return b.series.lastUpdated.compareTo(a.series.lastUpdated);
            case 'created_at':
              return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
            case 'updated_at':
              return (b.updatedAt ?? '').compareTo(a.updatedAt ?? '');
            case 'chapters_desc':
              final ca = int.tryParse(a.series.totalChapters) ?? 0;
              final cb = int.tryParse(b.series.totalChapters) ?? 0;
              return cb.compareTo(ca);
            case 'chapters_asc':
              final ca = int.tryParse(a.series.totalChapters) ?? 0;
              final cb = int.tryParse(b.series.totalChapters) ?? 0;
              return ca.compareTo(cb);
            case 'unread_desc':
              final ua = (int.tryParse(a.series.totalChapters) ?? 0) - (a.progressChapter ?? 0);
              final ub = (int.tryParse(b.series.totalChapters) ?? 0) - (b.progressChapter ?? 0);
              return ub.compareTo(ua);
            case 'unread_asc':
              final ua = (int.tryParse(a.series.totalChapters) ?? 0) - (a.progressChapter ?? 0);
              final ub = (int.tryParse(b.series.totalChapters) ?? 0) - (b.progressChapter ?? 0);
              return ua.compareTo(ub);
            default:
              return 0;
          }
        });
      }
    }

    _cachedFiltered = filtered;
    return filtered;
  }

  List<LibraryEntry> getByTab(String tabKey) {
    final filtered = getFilteredAndSorted();

    return filtered.where((entry) {
      var state = StateNormalizer.normalize(entry.state);
      if (!LibraryScreenConstants.knownStates.contains(state)) {
        state = 'reading';
      }
      
      return state == tabKey;
    }).toList();
  }
}
