import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';

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
    final queryParams = <String, String>{};
    if (query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final contentPrefs = SettingsManager().contentPreferences;
    
    // Build the final URI
    final finalQueryParams = <String, dynamic>{
      ...queryParams,
      'content_rating': contentPrefs,
    };

    if (extraParams != null) {
      finalQueryParams.addAll(extraParams);
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: finalQueryParams.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, value.toString());
      }),
    );

    _logger.info('Performing series search. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series search request timed out'),
          );

      _logger.fine('Series search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          final List data = json['data'] ?? [];
          final results = data
              .map((item) => Series.fromJson(item as Map<String, dynamic>))
              .toList();
          
          _logger.info('Search successful. Found ${results.length} results');
          
          for (var series in results) {
            _seriesService.precacheSeries(series);
          }
          
          return results;
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

  Future<SeriesSearchResult> searchSeries(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    final queryParams = <String, String>{};
    if (query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final contentPrefs = SettingsManager().contentPreferences;
    
    // Build the final URI
    final finalQueryParams = <String, dynamic>{
      ...queryParams,
      'content_rating': contentPrefs,
    };

    if (extraParams != null) {
      finalQueryParams.addAll(extraParams);
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: finalQueryParams.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, value.toString());
      }),
    );

    _logger.info('Performing series search. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series search request timed out'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final total = json['total'] as int? ?? 0;
        
        final results = data
            .map((item) => Series.fromJson(item as Map<String, dynamic>))
            .toList();
        
        for (var series in results) {
          _seriesService.precacheSeries(series);
        }
        
        return SeriesSearchResult(series: results, total: total);
      } else {
        throw ApiException(
          message: 'Failed to search series',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      _logger.severe('Error during series search: $e');
      rethrow;
    }
  }
}

class SeriesSearchResult {
  final List<Series> series;
  final int total;

  SeriesSearchResult({required this.series, required this.total});
}
