import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

class SeriesAutocompleteService {
  static final _logger = LoggingService.logger;

  final Map<String, List<AutocompleteSeriesResult>> _cache = {};

  Timer? _debounceTimer;

  http.Client? _activeClient;

  static const int minQueryLength = 3;

  static const int autocompleteLimit = 5;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

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

    final prefixResults = _findPrefixMatch(trimmed);
    if (prefixResults != null) {
      onResults(prefixResults);
    }

    // Debounce the actual network call
    _debounceTimer = Timer(_debounceDuration, () {
      _executeSearch(trimmed, onResults: onResults, onError: onError);
    });
  }

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

      _logger.fine('Autocomplete search request completed');

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
      // Request was cancelled
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

  void _cancelActiveRequest() {
    _activeClient?.close();
    _activeClient = null;
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _debounceTimer?.cancel();
    _cancelActiveRequest();
  }
}
