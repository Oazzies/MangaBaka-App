import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

/// Search autocomplete service for the Browse screen.
///
/// Rate limit context (GET /v1/series/search):
///   - 30 requests per minute (leaky bucket, per IP)
///   - Cloudflare caches exact URLs for 2 hours — a CF cache HIT is free
///
/// Strategy:
///   1. Client-side LRU-style cache keyed by the full query string.
///      Same session: free. Across sessions: must refetch.
///   2. Bidirectional prefix matching against the cache:
///      - If a *longer* cached query starts with the current query (backspace case),
///        filter those results client-side — no request needed.
///      - If the cached results for a shorter prefix are a *full page* (== limit),
///        there may be better results for the longer query — fire a request.
///      - If cached results for a shorter prefix are < limit, the server has no more
///        results for any extension of that query — skip the request entirely.
///   3. Debounce set to 220ms — fast enough to feel instant, but avoids firing a
///      request for every keystroke on fast typists (~5 chars/sec = one request per word).
///   4. Cancel in-flight requests when a newer query arrives.
///   5. On 429: keep existing suggestions, don't blank the UI.
class SeriesAutocompleteService {
  static final _logger = LoggingService.logger;

  final Map<String, List<AutocompleteSeriesResult>> _cache = {};

  Timer? _debounceTimer;
  http.Client? _activeClient;
  String? _pendingQuery;

  static const int minQueryLength = 2;
  static const int autocompleteLimit = 6;

  // 220ms: comfortable for fast typists, avoids a request per character
  static const Duration _debounceDuration = Duration(milliseconds: 220);

  void search(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) {
    _debounceTimer?.cancel();

    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < minQueryLength) {
      _cancelActiveRequest();
      onResults([]);
      return;
    }

    // 1. Exact cache hit — instant, zero network cost
    if (_cache.containsKey(trimmed)) {
      _cancelActiveRequest();
      onResults(_cache[trimmed]!);
      return;
    }

    // 2. Prefix match — check the cache
    final prefixResult = _findBestCachedMatch(trimmed);

    if (prefixResult != null) {
      // Always deliver the cached result immediately for low latency
      onResults(prefixResult.results);

      // Only fire a network request if the shorter prefix returned a full page.
      // A full page means there could be MORE relevant results for the longer query.
      // If the prefix returned < limit results, the server has exhausted its list —
      // no point asking for "attack on tit" if "attack on ti" already returned < 6.
      if (!prefixResult.couldHaveMore) {
        _logger.fine('Autocomplete: skipping network (prefix cache covers "$trimmed")');
        return;
      }
    }

    // 3. Debounce the network call
    _pendingQuery = trimmed;
    _debounceTimer = Timer(_debounceDuration, () {
      if (_pendingQuery == trimmed) {
        _executeSearch(trimmed, onResults: onResults, onError: onError);
      }
    });
  }

  _PrefixMatchResult? _findBestCachedMatch(String query) {
    // Case A: cached key is LONGER than query (backspace case)
    // e.g. cached "attack on titan", user types "attack on"
    String? bestLongerKey;
    for (final key in _cache.keys) {
      if (key.startsWith(query)) {
        if (bestLongerKey == null || key.length < bestLongerKey.length) {
          bestLongerKey = key;
        }
      }
    }
    if (bestLongerKey != null) {
      final filtered = _cache[bestLongerKey]!
          .where((r) => r.title.toLowerCase().contains(query))
          .take(autocompleteLimit)
          .toList();
      if (filtered.isNotEmpty) {
        // We derived these from a longer cached query, so we can't know if there
        // are more results for the shorter query — assume there could be more.
        return _PrefixMatchResult(results: filtered, couldHaveMore: true);
      }
    }

    // Case B: cached key is SHORTER than query (typing forward case)
    // e.g. cached "attack", user types "attack on"
    // Find the longest cached prefix of the current query
    String? bestShorterKey;
    for (final key in _cache.keys) {
      if (query.startsWith(key)) {
        if (bestShorterKey == null || key.length > bestShorterKey.length) {
          bestShorterKey = key;
        }
      }
    }
    if (bestShorterKey != null) {
      final cachedResults = _cache[bestShorterKey]!;
      final filtered = cachedResults
          .where((r) => r.title.toLowerCase().contains(query))
          .take(autocompleteLimit)
          .toList();
      if (filtered.isNotEmpty) {
        // If the prefix query returned fewer than the limit, the server is exhausted.
        // No need to send a more specific query — it can only return a subset.
        final couldHaveMore = cachedResults.length >= autocompleteLimit;
        return _PrefixMatchResult(results: filtered, couldHaveMore: couldHaveMore);
      }
      // Even if filtered is empty, if the shorter query was already exhausted
      // (< limit results), we know the extended query will also be empty.
      if (cachedResults.length < autocompleteLimit) {
        return _PrefixMatchResult(results: [], couldHaveMore: false);
      }
    }

    return null;
  }

  Future<void> _executeSearch(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) async {
    _cancelActiveRequest();

    final client = http.Client();
    _activeClient = client;

    final params = StringBuffer(
      '${AppConstants.baseApiUrl}/series/search'
      '?q=${Uri.encodeComponent(query)}'
      '&limit=$autocompleteLimit'
      '&sort_by=relevance_desc',
    );

    final contentPrefs = SettingsManager().contentPreferences;
    for (final rating in contentPrefs) {
      params.write('&content_rating=${Uri.encodeComponent(rating)}');
    }

    try {
      final response = await client
          .get(Uri.parse(params.toString()), headers: {'User-Agent': AppConstants.userAgent})
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (_activeClient != client) return; // Superseded

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final results = data
            .map((item) => AutocompleteSeriesResult.fromJson(item as Map<String, dynamic>))
            .toList();

        _cache[query] = results;
        _logger.fine('Autocomplete: ${results.length} results for "$query" '
            '(cache: ${response.headers['cf-cache-status'] ?? 'unknown'})');
        onResults(results);
      } else if (response.statusCode == 429) {
        _logger.warning('Autocomplete rate-limited (429) for query: $query');
        onError?.call('rate_limited');
        // Keep existing results in UI — don't blank them out
      } else {
        _logger.warning('Autocomplete search failed: ${response.statusCode}');
        onResults([]);
      }
    } on http.ClientException {
      if (_activeClient != client) return;
    } on SocketException {
      if (_activeClient != client) return;
      _logger.warning('Network error during autocomplete search');
      onError?.call('no_internet');
    } on TimeoutException {
      if (_activeClient != client) return;
      _logger.warning('Autocomplete timed out for query: $query');
    } catch (e) {
      if (_activeClient != client) return;
      _logger.warning('Unexpected autocomplete error: $e');
    }
  }

  void _cancelActiveRequest() {
    _activeClient?.close();
    _activeClient = null;
  }

  void clearCache() => _cache.clear();

  void dispose() {
    _debounceTimer?.cancel();
    _cancelActiveRequest();
  }
}

class _PrefixMatchResult {
  final List<AutocompleteSeriesResult> results;
  /// True if a network request should still be fired to get potentially better results.
  final bool couldHaveMore;
  _PrefixMatchResult({required this.results, required this.couldHaveMore});
}
