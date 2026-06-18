import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/utils/uri_utils.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

class SeriesSearchService {
  static final String _baseUrl = '${AppConstants.baseApiUrl}/series/search';
  final _logger = LoggingService.logger;
  final _metadataService = getIt<MetadataService>();
  final _seriesService = getIt<SeriesService>();
  final http.Client _client;

  SeriesSearchService({http.Client? client}) : _client = client ?? http.Client();

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
    final result = await _executeSearch(
      query,
      sortBy: sortBy,
      type: type,
      extraParams: extraParams,
      removeSortByWithQuery: true,
    );
    return result.series;
  }

  Future<SeriesSearchResult> searchSeries(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    return _executeSearch(
      query,
      sortBy: sortBy,
      type: type,
      extraParams: extraParams,
      removeSortByWithQuery: true,
    );
  }

  Future<SeriesSearchResult> _executeSearch(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
    bool removeSortByWithQuery = false,
  }) async {
    final queryParams = <String, String>{};
    if (query.isNotEmpty) queryParams['q'] = query;
    if (sortBy != null && sortBy.isNotEmpty && (query.isEmpty || !removeSortByWithQuery)) {
      queryParams['sort_by'] = sortBy;
    }
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final contentPrefs = SettingsManager().contentPreferences;

    final finalQueryParams = <String, dynamic>{
      ...queryParams,
      'content_rating': contentPrefs,
    };

    if (extraParams != null) {
      finalQueryParams.addAll(extraParams);
      // Backend ignores 'sort_by' when 'q' is present — strip it so the
      // locally-applied sort in BrowseController is the source of truth.
      if (query.isNotEmpty) finalQueryParams.remove('sort_by');
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: UriUtils.encodeQueryParameters(finalQueryParams),
    );

    _logger.info('Performing series search. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series search request timed out'),
          );

      _logger.fine('Series search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          final total = json['total'] as int? ?? 0;
          final List data = json['data'] ?? [];

          final results = data
              .map((item) => Series.fromJson(item as Map<String, dynamic>))
              .where((s) {
                if (contentPrefs.isNotEmpty &&
                    !contentPrefs.contains(s.contentRating.toLowerCase())) {
                  return false;
                }

                // Local rating filtering to ensure it matches our calculated combined average
                final ratingLower = extraParams?['rating_lower'] as num?;
                final ratingUpper = extraParams?['rating_upper'] as num?;
                if (ratingLower != null || ratingUpper != null) {
                  final rawRating = double.tryParse(s.rating) ?? 0.0;
                  final rating = rawRating <= 10.0 ? rawRating * 10 : rawRating;
                  if (ratingLower != null && rating < ratingLower) return false;
                  if (ratingUpper != null && rating > ratingUpper) return false;
                } else if (sortBy != null && sortBy.startsWith('score_')) {
                  // Explicitly exclude unrated series when sorting by community rating
                  final rating = double.tryParse(s.rating) ?? 0;
                  if (rating == 0) return false;
                }

                return true;
              })
              .toList();

          _logger.info('Search successful. Found ${results.length} results (total: $total)');
          for (final series in results) {
            _seriesService.precacheSeries(series);
          }

          return SeriesSearchResult(series: results, total: total);
        } catch (e, st) {
          _logger.severe('Failed to parse series search response', e, st);
          throw ParseException(
            message: 'Failed to parse series search response',
            originalError: e,
            stackTrace: st,
          );
        }
      } else {
        _logger.severe(
          'Series search failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to search series',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'SEARCH_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error during series search', e, st);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error during series search', e, st);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout during series search', e, st);
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on ParseException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error during series search', e, st);
      throw AppError(
        message: 'An unexpected error occurred while searching for series',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}

class SeriesSearchResult {
  final List<Series> series;
  final int total;

  SeriesSearchResult({required this.series, required this.total});
}
