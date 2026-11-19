import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/services/autocomplete_cache.dart';

/// GET /v1/series/search allows 30 req/min per IP (leaky bucket); Cloudflare caches exact URLs for 2h.
/// Bypasses [ApiClient]'s throwing contract: results come by callback; closing the per-request client cancels.
class SeriesAutocompleteService {
  static final _logger = LoggingService.logger;

  static const int minQueryLength = 2;
  static const int autocompleteLimit = 6;

  static const Duration _debounceDuration = Duration(milliseconds: 220);

  static const Duration _timeout = Duration(
    seconds: AppConstants.networkTimeoutSeconds,
  );

  final AutocompleteCache _cache = AutocompleteCache(
    pageLimit: autocompleteLimit,
  );

  Timer? _debounceTimer;
  http.Client? _activeClient;
  String? _pendingQuery;

  void search(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) {
    _debounceTimer?.cancel();

    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < minQueryLength) {
      _cancelActiveRequest();
      onResults(const []);
      return;
    }

    final exact = _cache.get(trimmed);
    if (exact != null) {
      _cancelActiveRequest();
      onResults(exact);
      return;
    }

    final prefixHit = _cache.findPrefixMatch(trimmed);
    if (prefixHit != null) {
      onResults(prefixHit.results);
      if (!prefixHit.couldHaveMore) {
        // An in-flight request is for an older query and would overwrite these results.
        _cancelActiveRequest();
        _logger.fine(
          'Autocomplete: skipping network (prefix cache covers "$trimmed")',
        );
        return;
      }
    }

    _pendingQuery = trimmed;
    _debounceTimer = Timer(_debounceDuration, () {
      if (_pendingQuery != trimmed) return;
      _executeSearch(trimmed, onResults: onResults, onError: onError);
    });
  }

  Uri _buildUri(String query) =>
      ApiClient.uri('${AppConstants.baseApiUrl}/series/search', {
        'q': query,
        'limit': autocompleteLimit,
        'sort_by': 'relevance_desc',
        'content_rating': SettingsManager().contentPreferences,
      });

  Future<void> _executeSearch(
    String query, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) async {
    _cancelActiveRequest();

    final client = http.Client();
    _activeClient = client;

    try {
      final response = await client
          .get(
            _buildUri(query),
            headers: {'User-Agent': AppConstants.userAgent},
          )
          .timeout(_timeout);

      if (_activeClient != client) return;

      _handleResponse(query, response, onResults: onResults, onError: onError);
    } on http.ClientException {
      // Expected when [_cancelActiveRequest] closes the client mid-flight.
      if (_activeClient != client) return;
      _logger.warning('Autocomplete client error for query: $query');
    } on SocketException {
      if (_activeClient != client) return;
      _logger.warning('Network error during autocomplete search');
      onError?.call('no_internet');
    } on TimeoutException {
      if (_activeClient != client) return;
      _logger.warning('Autocomplete timed out for query: $query');
    } catch (e, st) {
      if (_activeClient != client) return;
      _logger.warning('Unexpected autocomplete error: $e', e, st);
    } finally {
      // Left open, each per-request client holds its socket and TLS session until the idle timeout.
      client.close();
      if (identical(_activeClient, client)) _activeClient = null;
    }
  }

  void _handleResponse(
    String query,
    http.Response response, {
    required void Function(List<AutocompleteSeriesResult> results) onResults,
    void Function(String message)? onError,
  }) {
    if (response.statusCode == 429) {
      _logger.warning('Autocomplete rate-limited (429) for query: $query');
      onError?.call('rate_limited');
      // Deliberately no onResults: keep the suggestions already on screen.
      return;
    }

    if (response.statusCode != 200) {
      _logger.warning('Autocomplete search failed: ${response.statusCode}');
      onResults(const []);
      return;
    }

    final List<AutocompleteSeriesResult> results;
    try {
      results = parseDataList(
        jsonDecode(response.body),
        AutocompleteSeriesResult.fromJson,
      );
    } catch (e) {
      // A malformed suggestion payload is not worth an error state in a search field.
      _logger.warning('Failed to parse autocomplete response: $e');
      onResults(const []);
      return;
    }

    _cache.put(query, results);
    _logger.fine(
      'Autocomplete: ${results.length} results for "$query" '
      '(cache: ${response.headers['cf-cache-status'] ?? 'unknown'})',
    );
    onResults(results);
  }

  void _cancelActiveRequest() {
    _activeClient?.close();
    _activeClient = null;
  }

  void clearCache() => _cache.clear();

  void dispose() {
    _debounceTimer?.cancel();
    _pendingQuery = null;
    _cancelActiveRequest();
  }
}
