import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/series/models/autocomplete_series_result.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

/// Service that handles autocomplete search against the MangaBaka API.
///
/// Features:
/// - **Debouncing**: 300ms delay before firing a request.
/// - **Min length gate**: Queries shorter than 3 characters are rejected.
/// - **Request cancellation**: In-flight HTTP requests are cancelled when a
///   newer query arrives (via [http.Client.close]).
/// - **Smart caching**: Exact match first, then prefix match from longer
///   cached queries to provide instant suggestions while typing.
/// - **Content preferences**: Automatically applies the user's content
///   rating preferences to narrow results.
/// - **Rate-limit awareness**: HTTP 429 responses are caught gracefully.
class SeriesAutocompleteService {
  static final _logger = LoggingService.logger;

  /// In-memory cache: query string → parsed results.
  final Map<String, List<AutocompleteSeriesResult>> _cache = {};

  /// Currently active debounce timer.
  Timer? _debounceTimer;

  /// The HTTP client for the current in-flight request.
  /// Closing it cancels the pending request.
  http.Client? _activeClient;

  /// Minimum query length before we hit the network.
  static const int minQueryLength = 3;

  /// Number of results to request from the API.
  static const int autocompleteLimit = 5;

  /// Debounce duration — 300ms for a snappy feel.
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// Search with debouncing and cancellation.
  ///
  /// [query] is the raw user input.
  /// [onResults] is called with the list of results (may be empty).
  /// [onError] is called with a user-friendly error message (optional).
  void search(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // Gate: clear results for short queries
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < minQueryLength) {
      _cancelActiveRequest();
      onResults([]);
      return;
    }

    // Check exact cache hit first (instant, no debounce)
    if (_cache.containsKey(trimmed)) {
      _cancelActiveRequest();
      onResults(_cache[trimmed]!);
      return;
    }

    // Check for a prefix match — if we already fetched "naruto" and the
    // user now types "naru", filter from the longer cached result set.
    // This gives instant intermediate results while the real query debounces.
    final prefixResults = _findPrefixMatch(trimmed);
    if (prefixResults != null) {
      onResults(prefixResults);
      // Still debounce the real request for the shorter query in case
      // the API returns different/better results
    }

    // Debounce the actual network call
    _debounceTimer = Timer(_debounceDuration, () {
      _executeSearch(trimmed, onResults: onResults, onError: onError);
    });
  }

  /// Try to find cached results from a longer query that starts with [query].
  /// Returns filtered results or null if no match.
  List<AutocompleteSeriesResult>? _findPrefixMatch(String query) {
    for (final entry in _cache.entries) {
      if (entry.key.startsWith(query) && entry.value.isNotEmpty) {
        // Filter: keep results whose title contains the query
        final filtered = entry.value
            .where((r) => r.title.toLowerCase().contains(query))
            .toList();
        if (filtered.isNotEmpty) return filtered.take(autocompleteLimit).toList();
      }
    }
    return null;
  }

  /// Execute the actual API call.
  Future<void> _executeSearch(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) async {
    // Cancel any previous in-flight request
    _cancelActiveRequest();

    // Create a new client for this request so we can cancel it later
    final client = http.Client();
    _activeClient = client;

    // Build URL with content preferences
    String url = '${AppConstants.baseApiUrl}/series/search'
        '?q=${Uri.encodeComponent(query)}'
        '&limit=$autocompleteLimit';

    final contentPrefs = SettingsManager().contentPreferences;
    for (var rating in contentPrefs) {
      url += '&content_rating=${Uri.encodeComponent(rating)}';
    }

    try {
      final response = await client
          .get(Uri.parse(url), headers: {'User-Agent': AppConstants.userAgent})
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      print("Autocomplete API");

      // If this client was cancelled while waiting, bail out silently
      if (_activeClient != client) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final results = data
            .map((item) => AutocompleteSeriesResult.fromJson(
                item as Map<String, dynamic>))
            .toList();

        // Cache the results
        _cache[query] = results;
        onResults(results);
      } else if (response.statusCode == 429) {
        _logger.warning('Autocomplete rate-limited (429) for query: $query');
        onError?.call('Too many requests. Please slow down.');
        onResults([]);
      } else {
        _logger.warning(
          'Autocomplete search failed. Status: ${response.statusCode}',
        );
        onResults([]);
      }
    } on http.ClientException {
      // Request was cancelled — this is expected, do nothing
      if (_activeClient != client) return;
    } on SocketException {
      if (_activeClient != client) return;
      _logger.warning('Network error during autocomplete search');
      onError?.call('No internet connection.');
      onResults([]);
    } on TimeoutException {
      if (_activeClient != client) return;
      _logger.warning('Autocomplete search timed out for query: $query');
      onResults([]);
    } catch (e) {
      if (_activeClient != client) return;
      _logger.warning('Unexpected error during autocomplete: $e');
      onResults([]);
    }
  }

  /// Cancel the in-flight HTTP request by closing its client.
  void _cancelActiveRequest() {
    _activeClient?.close();
    _activeClient = null;
  }

  /// Clear the in-memory cache (e.g. when the user navigates away).
  void clearCache() {
    _cache.clear();
  }

  /// Clean up resources. Call this from the widget's [dispose].
  void dispose() {
    _debounceTimer?.cancel();
    _cancelActiveRequest();
  }
}
