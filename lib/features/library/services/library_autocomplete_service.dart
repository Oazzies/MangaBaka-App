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
    final scored = <_ScoredMatch>[];

    for (final entry in allEntries) {
      final series = entry.series;
      final titleLower = series.title.toLowerCase();
      final nativeLower = series.nativeTitle.toLowerCase();
      final romanizedLower = series.romanizedTitle.toLowerCase();

      int score = 0;
      if (titleLower.startsWith(q)) {
        score = 100; // Strongest match
      } else if (nativeLower.startsWith(q) || romanizedLower.startsWith(q)) {
        score = 90;
      } else {
        bool secondaryStarts = false;
        for (var t in series.secondaryTitles) {
          if (t.toLowerCase().startsWith(q)) {
            secondaryStarts = true;
            break;
          }
        }
        if (secondaryStarts) {
          score = 80;
        } else if (titleLower.contains(q)) {
          score = 50;
        } else if (nativeLower.contains(q) || romanizedLower.contains(q)) {
          score = 40;
        } else {
          bool secondaryContains = false;
          for (var t in series.secondaryTitles) {
            if (t.toLowerCase().contains(q)) {
              secondaryContains = true;
              break;
            }
          }
          if (secondaryContains) {
            score = 30;
          }
        }
      }

      if (score > 0) {
        scored.add(_ScoredMatch(score: score, entry: entry));
      }
    }

    // Secondary sort by title length (prefer shorter matches if scores are equal)
    scored.sort((a, b) {
      if (b.score != a.score) return b.score.compareTo(a.score);
      return a.entry.series.title.length.compareTo(b.entry.series.title.length);
    });

    final topMatches = scored.take(maxResults);

    return topMatches.map((match) {
      final series = match.entry.series;

      int? year;
      if (series.year.isNotEmpty) {
        year = int.tryParse(
          series.year.length >= 4 ? series.year.substring(0, 4) : series.year,
        );
      }

      final List<String> allTitles = [
        series.title,
        series.nativeTitle,
        series.romanizedTitle,
        ...series.secondaryTitles,
      ].where((t) => t.isNotEmpty).toSet().toList();

      return AutocompleteSeriesResult(
        id: int.tryParse(series.id) ?? 0,
        title: series.title,
        thumbnailUrl: series.coverUrl,
        type: series.type,
        year: year,
        genres: series.genres.take(3).toList(),
        allTitles: allTitles,
      );
    }).toList();
  }
}

class _ScoredMatch {
  final int score;
  final LibraryEntry entry;
  _ScoredMatch({required this.score, required this.entry});
}
