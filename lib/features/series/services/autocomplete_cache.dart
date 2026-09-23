import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

/// What the cache could answer for a query, and whether the network still has
/// anything to add.
class AutocompleteCacheHit {
  final List<AutocompleteSeriesResult> results;

  /// True when a request should still be fired because the server may hold
  /// better matches than the cache could derive.
  final bool couldHaveMore;

  const AutocompleteCacheHit({
    required this.results,
    required this.couldHaveMore,
  });
}

/// A bounded, prefix-aware cache of autocomplete results.
///
/// Extracted from `SeriesAutocompleteService` because it is pure logic with no
/// I/O — the part of autocomplete most worth testing directly, and the part
/// that decides whether a keystroke costs a request at all. The search
/// endpoint allows 30 requests per minute per IP, so every avoided request is
/// headroom for the ones that matter.
///
/// Two prefix relationships are exploited:
///
/// * A cached query that *extends* the current one (the backspace case) can be
///   filtered down locally, but cannot prove the shorter query has no better
///   matches — so a request still follows.
/// * A cached query that the current one extends (typing forward) is
///   conclusive when it came back under [pageLimit]: the server had already
///   exhausted its matches, and a narrower query can only return a subset.
class AutocompleteCache {
  /// The page size requested from the server. A response of exactly this size
  /// means "there may be more"; anything less means the server is exhausted.
  final int pageLimit;

  /// Upper bound on cached queries. A long browsing session would otherwise
  /// grow the cache without limit. Eviction is LRU: hits refresh recency.
  final int maxEntries;

  /// Insertion-ordered, which is what makes `keys.first` the least recently
  /// used entry — [get] and [put] both re-insert on access to maintain it.
  final Map<String, List<AutocompleteSeriesResult>> _entries = {};

  AutocompleteCache({this.pageLimit = 6, this.maxEntries = 64});

  int get length => _entries.length;

  /// An exact hit, promoted to most-recently-used. Null when absent.
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

  /// The best answer derivable from cached neighbours of [query], or null when
  /// the cache has nothing to say and the caller must go to the network.
  ///
  /// Both prefix directions are found in a single pass over the keys; this
  /// runs on every keystroke, so it stays O(entries) rather than the two full
  /// scans it used to take.
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
      // Derived from a longer query, so it cannot speak for the shorter one:
      // there may be matches the longer query excluded.
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
      // No local matches *and* the server was already exhausted for the
      // shorter query — the extended query is provably empty too.
      if (exhausted) {
        return const AutocompleteCacheHit(results: [], couldHaveMore: false);
      }
    }

    return null;
  }

  /// Keeps the results the server could have returned for [query].
  ///
  /// The server matches on every title a series has (alternate, native,
  /// romanized), not just the one displayed, and matches words rather than
  /// one contiguous substring. Filtering on the display title alone dropped
  /// results the server would have kept — and when that emptied the list,
  /// the "exhausted" branch above declared the query provably empty and
  /// skipped the network, so real matches never appeared.
  List<AutocompleteSeriesResult> _filter(
    List<AutocompleteSeriesResult> source,
    String query,
  ) {
    final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    bool titleMatches(String title) {
      final lower = title.toLowerCase();
      return words.every(lower.contains);
    }

    return source
        .where((r) => titleMatches(r.title) || r.allTitles.any(titleMatches))
        .take(pageLimit)
        .toList();
  }
}
