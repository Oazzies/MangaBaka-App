import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

/// Instant, local-DB backed autocomplete for the Library screen.
/// No network calls, no debounce — results are immediate.
class LibraryAutocompleteService {
  static const int maxResults = 6;

  List<AutocompleteSeriesResult> search(
    String query,
    List<LibraryEntry> allEntries,
  ) {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    // Score and sort: title-start matches rank higher than contains matches
    final scored = <_ScoredResult>[];

    for (final entry in allEntries) {
      final series = entry.series;
      final titleLower = series.title.toLowerCase();
      final nativeLower = series.nativeTitle.toLowerCase();
      final romanizedLower = series.romanizedTitle.toLowerCase();
      
      final secondaryLowers = series.secondaryTitles.map((t) => t.toLowerCase()).toList();

      int score = 0;
      if (titleLower.startsWith(q)) {
        score = 100; // Strongest match
      } else if (nativeLower.startsWith(q) || romanizedLower.startsWith(q)) {
        score = 90;
      } else if (secondaryLowers.any((t) => t.startsWith(q))) {
        score = 80;
      } else if (titleLower.contains(q)) {
        score = 50;
      } else if (nativeLower.contains(q) || romanizedLower.contains(q) || secondaryLowers.any((t) => t.contains(q))) {
        score = 40;
      }

      if (score > 0) {
        // Parse year from series
        int? year;
        if (series.year.isNotEmpty) {
          year = int.tryParse(series.year.length >= 4 ? series.year.substring(0, 4) : series.year);
        }

        final List<String> allTitles = [
          series.title,
          series.nativeTitle,
          series.romanizedTitle,
          ...series.secondaryTitles,
        ].where((t) => t.isNotEmpty).toSet().toList();

        scored.add(_ScoredResult(
          score: score,
          result: AutocompleteSeriesResult(
            id: int.tryParse(series.id) ?? 0,
            title: series.title,
            thumbnailUrl: series.coverUrl,
            type: series.type,
            year: year,
            genres: series.genres.take(3).toList(),
            allTitles: allTitles,
          ),
        ));
      }
    }

    // Secondary sort by title length (prefer shorter matches if scores are equal)
    scored.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      return a.result.title.length.compareTo(b.result.title.length);
    });
    
    return scored.take(maxResults).map((s) => s.result).toList();
  }
}

class _ScoredResult {
  final int score;
  final AutocompleteSeriesResult result;
  _ScoredResult({required this.score, required this.result});
}
