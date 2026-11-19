import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class AutocompleteRanking {
  AutocompleteRanking._();

  /// Exact, prefix, then shortest: a long title containing the query is usually a spin-off.
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
