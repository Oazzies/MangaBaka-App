import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_filter.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

/// Reads `/series/search` and exposes the genre/tag vocabularies the search
/// filters are built from.
///
/// Request plumbing lives in [ApiClient]; the client-side result filtering
/// that the backend cannot express lives in [SeriesSearchFilter].
class SeriesSearchService {
  static final String _baseUrl = '${AppConstants.baseApiUrl}/series/search';

  final _logger = LoggingService.logger;
  final _metadataService = getIt<MetadataService>();
  final _seriesService = getIt<SeriesService>();
  final ApiClient _api;

  SeriesSearchService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'series-search', client: client);

  Future<List<Map<String, dynamic>>> getGenres() async {
    if (!_metadataService.isInitialized) {
      await _metadataService.fetchGenres();
    }
    return _metadataService.genres;
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    if (!_metadataService.isInitialized) {
      await _metadataService.fetchTags();
    }
    return _metadataService.tags;
  }

  Future<List<Series>> searchSeriesByName(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    final result = await searchSeries(
      query,
      sortBy: sortBy,
      type: type,
      extraParams: extraParams,
    );
    return result.series;
  }

  Future<SeriesSearchResult> searchSeries(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    final contentPrefs = SettingsManager().contentPreferences;
    final params = _buildParams(
      query: query,
      sortBy: sortBy,
      type: type,
      contentPrefs: contentPrefs,
      extraParams: extraParams,
    );

    final filter = SeriesSearchFilter(
      contentPreferences: contentPrefs,
      ratingLower: (extraParams?['rating_lower'] as num?)?.toDouble(),
      ratingUpper: (extraParams?['rating_upper'] as num?)?.toDouble(),
      sortBy: sortBy,
    );

    final result = await _api.getJson(
      ApiClient.uri(_baseUrl, params),
      operation: 'search series',
      parse: (json) => SeriesSearchResult(
        series: parseDataList(
          json,
          Series.fromJson,
        ).where(filter.allows).toList(),
        total: totalCount(json),
      ),
    );

    _logger.info(
      'Search successful. Found ${result.series.length} results '
      '(total: ${result.total})',
    );
    for (final series in result.series) {
      _seriesService.precacheSeries(series);
    }
    return result;
  }

  /// Assembles the query string.
  ///
  /// `sort_by` is stripped whenever a text query is present: the backend
  /// ignores it in that case, and leaving it in would imply the results were
  /// server-sorted when the locally-applied sort in `BrowseController` is
  /// actually the source of truth.
  Map<String, dynamic> _buildParams({
    required String query,
    required String? sortBy,
    required String? type,
    required List<String> contentPrefs,
    required Map<String, dynamic>? extraParams,
  }) {
    final hasQuery = query.isNotEmpty;
    final params = <String, dynamic>{
      if (hasQuery) 'q': query,
      if (!hasQuery) 'sort_by': sortBy,
      'type': type,
      'content_rating': contentPrefs,
      ...?extraParams,
    };
    // A content-rating filter narrows what the user's preference allows; it
    // must never widen it, so the two are intersected.
    final picked = extraParams?['content_rating'];
    if (picked is List && picked.isNotEmpty) {
      final allowed = contentPrefs.toSet();
      final both = [
        for (final r in picked)
          if (allowed.isEmpty || allowed.contains(r)) r,
      ];
      params['content_rating'] = both.isEmpty ? contentPrefs : both;
    }
    if (hasQuery) params.remove('sort_by');
    return params;
  }

  void dispose() => _api.close();
}

class SeriesSearchResult {
  final List<Series> series;
  final int total;

  SeriesSearchResult({required this.series, required this.total});
}
