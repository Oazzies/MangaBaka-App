import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class SeriesService {
  static final _logger = LoggingService.logger;

  static Future<Series> fetchSeries(String id) async {
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
          return Series.fromJson(data['data']);
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
}
