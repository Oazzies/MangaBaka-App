import 'package:mangabaka_app/core/utils/search_utils.dart';
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

    final prepared = SearchUtils.prepare(query);

    // Score and sort: title-start matches rank higher than contains matches
    final scored = <_ScoredMatch>[];

    for (final entry in allEntries) {
      final series = entry.series;

      int score = 0;
      if (prepared.startsWith(series.title)) {
        score = 100; // Strongest match
      } else if (prepared.startsWith(series.nativeTitle) ||
          prepared.startsWith(series.romanizedTitle)) {
        score = 90;
      } else if (series.secondaryTitles.any(prepared.startsWith)) {
        score = 80;
      } else if (prepared.matches(series.title)) {
        score = 50;
      } else if (prepared.matches(series.nativeTitle) ||
          prepared.matches(series.romanizedTitle)) {
        score = 40;
      } else if (series.secondaryTitles.any(prepared.matches)) {
        score = 30;
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
