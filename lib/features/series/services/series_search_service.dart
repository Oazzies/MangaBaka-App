import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class SeriesSearchService {
  static final String _baseUrl = '${AppConstants.baseApiUrl}/series/search';
  final _logger = LoggingService.logger;
  final _metadataService = getIt<MetadataService>();

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


    try {
      final response = await http
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})

          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series search request timed out'),
          );

      _logger.fine('Series search request completed');

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          final List data = json['data'] ?? [];
          return data
              .map((item) => Series.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e, st) {
          _logger.severe('Failed to parse series search response: $e\n$st');
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
      _logger.severe('HTTP client error during series search: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error during series search: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout during series search: $e\n$st');
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
      _logger.severe('Unexpected error during series search: $e\n$st');
      throw AppError(
        message: 'An unexpected error occurred while searching for series',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
