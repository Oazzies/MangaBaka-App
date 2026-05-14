import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';

class PublisherSearchService {
  static final String _baseUrl = '${AppConstants.baseApiUrl}/publishers/search';
  final _logger = LoggingService.logger;
  final http.Client _client;

  PublisherSearchService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Publisher>> searchPublishers({
    String? query,
    String? type,
    bool? closed,
    int? yearLower,
    int? yearUpper,
    int? page,
    int? limit,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (closed != null) queryParams['closed'] = closed.toString();
    if (yearLower != null) queryParams['year_lower'] = yearLower.toString();
    if (yearUpper != null) queryParams['year_upper'] = yearUpper.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
    
    _logger.info('Performing publisher search. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Publisher search request timed out'),
          );

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          final List data = json['data'] ?? [];
          final results = data
              .map((item) => Publisher.fromJson(item as Map<String, dynamic>))
              .toList();
          
          _logger.info('Search successful. Found ${results.length} results');
          return results;
        } catch (e, st) {
          _logger.severe('Failed to parse publisher search response', e, st);
          throw ParseException(
            message: 'Failed to parse publisher search response',
            originalError: e,
            stackTrace: st,
          );
        }
      } else {
        _logger.severe(
          'Publisher search failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to search publishers',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'SEARCH_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      _logger.severe('HTTP client error during publisher search', e, st);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error during publisher search', e, st);
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout during publisher search', e, st);
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } catch (e, st) {
      _logger.severe('Unexpected error during publisher search', e, st);
      throw AppError(
        message: 'An unexpected error occurred while searching for publishers',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<Publisher> getPublisherFull(String id) async {
    final uri = Uri.parse('${AppConstants.baseApiUrl}/publishers/$id/full');
    _logger.info('Fetching full publisher details. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Publisher full fetch timed out'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Publisher.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: 'Failed to fetch publisher details',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e, st) {
      _logger.severe('Error fetching full publisher details', e, st);
      rethrow;
    }
  }

  Future<PublisherSearchResult> search(Map<String, dynamic> params) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
    );

    _logger.info('Performing publisher search. URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Publisher search request timed out'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final total = json['total'] as int? ?? 0;
        
        final results = data
            .map((item) => Publisher.fromJson(item as Map<String, dynamic>))
            .toList();
        
        return PublisherSearchResult(publishers: results, total: total);
      } else {
        throw ApiException(
          message: 'Failed to search publishers',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (e) {
      _logger.severe('Error during publisher search: $e');
      rethrow;
    }
  }
}

class PublisherSearchResult {
  final List<Publisher> publishers;
  final int total;

  PublisherSearchResult({required this.publishers, required this.total});
}
