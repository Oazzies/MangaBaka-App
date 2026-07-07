import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
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

    // Lowercase the query and filter lists once, not per entry — this runs on
    // every keystroke against the whole library.
    final queryLower = query.toLowerCase();
    final f = filters;
    final typeLower = f?.type.map((t) => t.toLowerCase()).toSet() ?? const <String>{};
    final typeNotLower = f?.typeNot.map((t) => t.toLowerCase()).toSet() ?? const <String>{};
    final statusLower = f?.status.map((s) => s.toLowerCase()).toSet() ?? const <String>{};
    final statusNotLower = f?.statusNot.map((s) => s.toLowerCase()).toSet() ?? const <String>{};
    final genreLower = f?.genre.map((g) => g.toLowerCase()).toList() ?? const <String>[];
    final genreNotLower = f?.genreNot.map((g) => g.toLowerCase()).toList() ?? const <String>[];
    final tagLower = f?.tag.map((t) => t.toLowerCase()).toList() ?? const <String>[];
    final tagNotLower = f?.tagNot.map((t) => t.toLowerCase()).toList() ?? const <String>[];

    List<LibraryEntry> filtered = allEntries.where((entry) {
      // 1. Query Search
      final matchesQuery = queryLower.isEmpty ||
          entry.series.title.toLowerCase().contains(queryLower) ||
          entry.series.nativeTitle.toLowerCase().contains(queryLower) ||
          entry.series.romanizedTitle.toLowerCase().contains(queryLower);
      if (!matchesQuery) return false;

      // 2. Content Rating (Settings)
      final matchesRating = contentPreferences.isEmpty ||
          contentPreferences.contains(entry.series.contentRating.toLowerCase());
      if (!matchesRating) return false;

      if (f != null) {
        // 3. Series Type
        if (typeLower.isNotEmpty && !typeLower.contains(entry.series.type.toLowerCase())) return false;
        if (typeNotLower.isNotEmpty && typeNotLower.contains(entry.series.type.toLowerCase())) return false;

        // 4. Series Status
        if (statusLower.isNotEmpty && !statusLower.contains(entry.series.status.toLowerCase())) return false;
        if (statusNotLower.isNotEmpty && statusNotLower.contains(entry.series.status.toLowerCase())) return false;

        // 5. Genres
        if (genreLower.isNotEmpty || genreNotLower.isNotEmpty) {
          final entryGenres = entry.series.genres.map((g) => g.toLowerCase()).toSet();
          if (genreLower.isNotEmpty && !genreLower.every(entryGenres.contains)) return false;
          if (genreNotLower.isNotEmpty && genreNotLower.any(entryGenres.contains)) return false;
        }

        // 5b. Tags
        if (tagLower.isNotEmpty || tagNotLower.isNotEmpty) {
          final entryTags = entry.series.tags.map((t) => t.toLowerCase()).toSet();
          if (tagLower.isNotEmpty) {
            if (f.tagMode == 'and') {
              if (!tagLower.every(entryTags.contains)) return false;
            } else {
              if (!tagLower.any(entryTags.contains)) return false;
            }
          }
          if (tagNotLower.isNotEmpty && tagNotLower.any(entryTags.contains)) return false;
        }

        // 6. Rating (0-100)
        final rawRating = double.tryParse(entry.series.rating) ?? 0.0;
        final seriesRating = rawRating <= 10.0 ? rawRating * 10 : rawRating;
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
            case 'score_desc':
              final ra = double.tryParse(a.series.rating) ?? 0.0;
              final rb = double.tryParse(b.series.rating) ?? 0.0;
              return rb.compareTo(ra);
            case 'popularity_asc':
            case 'rating_asc':
            case 'score_asc':
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
