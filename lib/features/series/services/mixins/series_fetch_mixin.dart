import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

mixin SeriesFetchMixin {
  final logger = LoggingService.logger;
  final Map<String, Series> _cache = {};

  void precacheSeries(Series series) {
    _cache[series.id] = series;
  }

  Future<Series> fetchSeries(String id) async {
    if (_cache.containsKey(id)) {
      logger.fine('Returning cached series data for ID: $id');
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

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final series = Series.fromJson(data['data']);
          _cache[id] = series;
          return series;
        } catch (e, st) {
          logger.severe('Failed to parse series data: $e\n$st');
          throw ParseException(
            message: 'Failed to parse series data',
            originalError: e,
            stackTrace: st,
          );
        }
      } else if (response.statusCode == 404) {
        throw ApiException(
          message: 'Series not found',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'NOT_FOUND',
        );
      } else if (response.statusCode == 429) {
        throw ApiException(
          message: 'Too many requests. Please slow down.',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'RATE_LIMITED',
        );
      } else {
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
