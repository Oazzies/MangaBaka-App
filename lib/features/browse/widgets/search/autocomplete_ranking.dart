import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

/// Ordering and inline-completion rules shared by the Browse and Library
/// search fields.
///
/// Both had their own copy; they had already drifted — Browse ranked
/// prefix matches above the rest and Library did not, so the same query
/// produced a different first suggestion in each field.
class AutocompleteRanking {
  AutocompleteRanking._();

  /// Sorts [results] in place, best match first.
  ///
  /// Exact title match, then titles that begin with the query, then shortest
  /// title — a short title containing the query is almost always the series
  /// the user means, where a long one is usually a spin-off.
  ///
  /// [preferPrefixMatches] can be turned off for a source that has already
  /// scored matches itself.
  static void sort(
    List<AutocompleteSeriesResult> results,
    String query, {
    bool preferPrefixMatches = true,
  }) {
    final prepared = SearchUtils.prepare(query);
    results.sort((a, b) {
      final aExact = prepared.exactMatch(a.title);
      final bExact = prepared.exactMatch(b.title);
      if (aExact != bExact) return aExact ? -1 : 1;

      if (preferPrefixMatches) {
        final aStarts = prepared.startsWith(a.title);
        final bStarts = prepared.startsWith(b.title);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
      }

      return a.title.length.compareTo(b.title.length);
    });
  }

  /// The inline completion for [query]: the remainder of the first title,
  /// across all results and all their alternate titles, that [query] is a
  /// strict prefix of.
  ///
  /// Alternate titles are searched too, so typing an English title completes
  /// against a series filed under its romanised one. Returns an empty string
  /// when nothing extends the query.
  static String ghostSuffix(
    List<AutocompleteSeriesResult> results,
    String query,
  ) {
    if (query.isEmpty) return '';
    final q = query.toLowerCase();
    for (final result in results) {
      for (final title in result.allTitles) {
        if (title.length > query.length && title.toLowerCase().startsWith(q)) {
          return title.substring(query.length);
        }
      }
    }
    return '';
  }

  /// The result and full title that produced [ghostSuffix] for [query], so
  /// accepting the completion can select that result rather than just its
  /// text. Null when nothing matches — the ghost is stale.
  static ({AutocompleteSeriesResult result, String title})? matchForGhost(
    List<AutocompleteSeriesResult> results,
    String query,
    String ghostSuffix,
  ) {
    if (ghostSuffix.isEmpty) return null;
    final q = query.toLowerCase();
    for (final result in results) {
      for (final title in result.allTitles) {
        if (title.length >= query.length &&
            title.toLowerCase().startsWith(q) &&
            title.substring(query.length) == ghostSuffix) {
          return (result: result, title: title);
        }
      }
    }
    return null;
  }
}
