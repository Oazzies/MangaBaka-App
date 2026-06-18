import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

mixin SeriesFetchMixin {
  final logger = LoggingService.logger;
  final Map<String, Series> _cache = {};
  static const int _maxCacheSize = 200;

  void precacheSeries(Series series) {
    _cache[series.id] = series;
  }

  Future<Series> fetchSeries(String id) async {
    if (_cache.containsKey(id)) {
      final cached = _cache[id]!;
      final contentPrefs = SettingsManager().contentPreferences;
      if (contentPrefs.isNotEmpty && !contentPrefs.contains(cached.contentRating.toLowerCase())) {
        logger.warning('Cached series ${cached.title} ($id) no longer matches content preferences. Blocking.');
        _cache.remove(id);
        throw ApiException(
          message: 'This content is filtered by your content rating settings.',
          statusCode: 403,
          code: 'CONTENT_FILTERED',
        );
      }
      logger.fine('Returning cached series data for ID: $id');
      return cached;
    }

    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id");
      logger.info('Fetching series details for ID: $id. URL: $url');
      
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series fetch request timed out'),
          );

      logger.fine('Series fetch status for $id: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final series = Series.fromJson(data['data']);
          
          // Enforce content rating filtering
          final contentPrefs = SettingsManager().contentPreferences;
          if (contentPrefs.isNotEmpty && !contentPrefs.contains(series.contentRating.toLowerCase())) {
            logger.warning('Series ${series.title} (${series.id}) blocked due to content rating: ${series.contentRating}');
            throw ApiException(
              message: 'This content is filtered by your content rating settings.',
              statusCode: 403,
              code: 'CONTENT_FILTERED',
            );
          }

          logger.info('Successfully fetched series: ${series.title} ($id)');
          if (_cache.length >= _maxCacheSize) {
            _cache.remove(_cache.keys.first);
          }
          _cache[id] = series;
          return series;
        } catch (e, st) {
          logger.severe('Failed to parse series data for $id: $e\n$st');
          throw ParseException(
            message: 'Failed to parse series data',
            originalError: e,
            stackTrace: st,
          );
        }
      } else if (response.statusCode == 404) {
        logger.warning('Series not found: $id');
        throw ApiException(
          message: 'Series not found',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'NOT_FOUND',
        );
      } else if (response.statusCode == 429) {
        logger.warning('Rate limited while fetching series $id');
        throw ApiException(
          message: 'Too many requests. Please slow down.',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'RATE_LIMITED',
        );
      } else {
        logger.severe('Failed to fetch series $id. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(
          message: 'Failed to fetch series',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is ParseException || e is ApiException || e is NetworkException) {
        rethrow;
      }
      logger.severe('Unexpected error while fetching series: $e\n$st');
      throw AppError(
        message: 'An unexpected error occurred while fetching the series',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Series> get cache => _cache;
}
