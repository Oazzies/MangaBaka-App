import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/models/series_link.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/series/models/series_cover.dart';
import 'package:bakahyou/features/series/models/series_collection.dart';
import 'package:bakahyou/features/series/models/series_work.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class SeriesService {
  static final _logger = LoggingService.logger;
  static final Map<String, Series> _cache = {};
  
  static void precacheSeries(Series series) {
    _cache[series.id] = series;
  }

  static Future<List<SeriesLink>> fetchSeriesLinks(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/links");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series links fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesLink.fromJson(l)).toList();
        }
        _logger.warning('Expected list for series links, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching links for $id');
      }
      return [];
    } on SocketException catch (e) {
      _logger.warning('Network error while fetching links for $id: $e');
      return [];
    } on TimeoutException catch (e) {
      _logger.warning('Timeout while fetching links for $id: $e');
      return [];
    } catch (e) {
      _logger.warning('Unexpected error while fetching series links for ID: $id - $e');
      return [];
    }
  }

  static get logger => _logger;

  static Future<Series> fetchSeries(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      _logger.fine('Returning cached series data for ID: $id');
      return _cache[id]!;
    }

    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Series fetch request timed out'),
          );

      _logger.fine('Series ID fetch request completed');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final series = Series.fromJson(data['data']);

          // Store in cache
          _cache[id] = series;

          return series;
        } catch (e, st) {
          _logger.severe('Failed to parse series data: $e\n$st');
          throw ParseException(
            message: 'Failed to parse series data',
            originalError: e,
            stackTrace: st,
          );
        }
      } else if (response.statusCode == 404) {
        _logger.warning('Series not found: $id');
        throw ApiException(
          message: 'Series not found',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'NOT_FOUND',
        );
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching series: $id');
        throw ApiException(
          message: 'Too many requests. Please slow down.',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'RATE_LIMITED',
        );
      } else {
        _logger.severe(
          'Failed to fetch series. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to fetch series',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error while fetching series: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error while fetching series: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout while fetching series: $e\n$st');
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
      _logger.severe('Unexpected error while fetching series: $e\n$st');
      throw AppError(
        message: 'An unexpected error occurred while fetching the series',
        originalError: e,
        stackTrace: st,
      );
    }
  }
  static Future<List<SeriesCover>> fetchSeriesCovers(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/images?limit=50");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series covers fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesCover.fromJson(l)).toList();
        }
        _logger.warning('Expected list for series covers, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching covers for $id');
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching covers for $id: $e');
      return [];
    }
  }

  static Future<List<Series>> fetchSeriesRelated(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/related");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series related fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => Series.fromJson(l)).toList();
        }
        _logger.warning('Expected list for related series, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching related series for $id');
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching related series for $id: $e');
      return [];
    }
  }

  static Future<List<News>> fetchSeriesNews(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/news");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series news fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => News.fromJson(l)).toList();
        }
        _logger.warning('Expected list for series news, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching news for $id');
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching news for $id: $e');
      return [];
    }
  }

  static Future<List<SeriesCollection>> fetchSeriesCollections(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/collections");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series collections fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesCollection.fromJson(l)).toList();
        }
        _logger.warning('Expected list for series collections, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching collections for $id');
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching collections for $id: $e');
      return [];
    }
  }

  static Future<List<SeriesWork>> fetchSeriesWorks(String id) async {
    try {
      final url = Uri.parse("${AppConstants.baseApiUrl}/series/$id/works");
      final response = await http
          .get(url, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Series works fetch request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawData = data['data'];
        if (rawData is List) {
          return rawData.map((l) => SeriesWork.fromJson(l)).toList();
        }
        _logger.warning('Expected list for series works, got ${rawData.runtimeType}');
      } else if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching works for $id');
      }
      return [];
    } catch (e) {
      _logger.warning('Error fetching works for $id: $e');
      return [];
    }
  }
}
