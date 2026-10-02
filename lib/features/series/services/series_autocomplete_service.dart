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

/// Search autocomplete for the Browse and Library search fields.
///
/// Rate limit context (GET /v1/series/search):
///   - 30 requests per minute (leaky bucket, per IP)
///   - Cloudflare caches exact URLs for 2 hours — a CF cache HIT is free
///
/// Strategy:
///   1. [AutocompleteCache] answers exact repeats and prefix-derivable queries
///      without touching the network, and says when the server has nothing
///      left to add.
///   2. Debounce at 220ms — instant to the eye, but one request per word for
///      a fast typist rather than one per keystroke.
///   3. Cancel the in-flight request when a newer query arrives, by closing
///      its dedicated client.
///   4. On 429, keep the suggestions already on screen instead of blanking
///      them.
///
/// This is the one network path that does **not** go through [ApiClient]'s
/// throwing contract: results arrive by callback so the field can degrade
/// silently, and the per-request [http.Client] is the cancellation mechanism.
/// It still shares [ApiClient.uri] for URL building.
class SeriesAutocompleteService {
  static final _logger = LoggingService.logger;

  static const int minQueryLength = 2;
  static const int autocompleteLimit = 6;

  /// 220ms: comfortable for fast typists, avoids a request per character.
  static const Duration _debounceDuration = Duration(milliseconds: 220);

  static const Duration _timeout =
      Duration(seconds: AppConstants.networkTimeoutSeconds);

  final AutocompleteCache _cache =
      AutocompleteCache(pageLimit: autocompleteLimit);

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
      // Show what the cache knows straight away, then decide whether the
      // network could still improve on it.
      onResults(prefixHit.results);
      if (!prefixHit.couldHaveMore) {
        // A request still in flight belongs to an older query; letting it
        // land would overwrite these results with that query's.
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

  Uri _buildUri(String query) => ApiClient.uri(
        '${AppConstants.baseApiUrl}/series/search',
        {
          'q': query,
          'limit': autocompleteLimit,
          'sort_by': 'relevance_desc',
          'content_rating': SettingsManager().contentPreferences,
        },
      );

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
          .get(_buildUri(query),
              headers: {'User-Agent': AppConstants.userAgent})
          .timeout(_timeout);

      // A newer keystroke has already superseded this request; delivering its
      // results now would overwrite fresher suggestions.
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
      // One client per request: left open, each keeps its socket and TLS
      // session alive until the idle timeout.
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
      // A malformed suggestion payload is not worth an error state in a search
      // field; drop it and let the next keystroke try again.
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
