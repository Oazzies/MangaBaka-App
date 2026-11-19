import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class AutocompleteCacheHit {
  final List<AutocompleteSeriesResult> results;

  final bool couldHaveMore;

  const AutocompleteCacheHit({
    required this.results,
    required this.couldHaveMore,
  });
}

/// The search endpoint allows 30 requests per minute per IP, so this decides whether a keystroke costs one.
class AutocompleteCache {
  final int pageLimit;

  final int maxEntries;

  /// Relies on insertion order: `keys.first` is the LRU entry, so [get] and [put] re-insert.
  final Map<String, List<AutocompleteSeriesResult>> _entries = {};

  AutocompleteCache({this.pageLimit = 6, this.maxEntries = 64});

  int get length => _entries.length;

  List<AutocompleteSeriesResult>? get(String query) {
    final cached = _entries.remove(query);
    if (cached == null) return null;
    _entries[query] = cached;
    return cached;
  }

  void put(String query, List<AutocompleteSeriesResult> results) {
    _entries.remove(query);
    _entries[query] = results;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();

  AutocompleteCacheHit? findPrefixMatch(String query) {
    String? shortestExtension;
    String? longestPrefix;

    for (final key in _entries.keys) {
      if (key.length > query.length) {
        if (key.startsWith(query) &&
            (shortestExtension == null ||
                key.length < shortestExtension.length)) {
          shortestExtension = key;
        }
      } else if (query.startsWith(key)) {
        if (longestPrefix == null || key.length > longestPrefix.length) {
          longestPrefix = key;
        }
      }
    }

    if (shortestExtension != null) {
      final filtered = _filter(_entries[shortestExtension]!, query);
      // A longer query's results cannot rule out matches it excluded for this shorter one.
      if (filtered.isNotEmpty) {
        return AutocompleteCacheHit(results: filtered, couldHaveMore: true);
      }
    }

    if (longestPrefix != null) {
      final cached = _entries[longestPrefix]!;
      final exhausted = cached.length < pageLimit;
      final filtered = _filter(cached, query);
      if (filtered.isNotEmpty) {
        return AutocompleteCacheHit(
          results: filtered,
          couldHaveMore: !exhausted,
        );
      }
      // The shorter query was exhausted, so this narrower one is provably empty.
      if (exhausted) {
        return const AutocompleteCacheHit(results: [], couldHaveMore: false);
      }
    }

    return null;
  }

  /// Must match like the server (every title, word-wise), or the exhausted branch skips real matches.
  List<AutocompleteSeriesResult> _filter(
    List<AutocompleteSeriesResult> source,
    String query,
  ) {
    final prepared = SearchUtils.prepare(query);
    return source
        .where((r) => prepared.matches(r.title) || r.allTitles.any(prepared.matches))
        .take(pageLimit)
        .toList();
  }
}
