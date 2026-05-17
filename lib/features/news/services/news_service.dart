import 'dart:convert';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  static final _logger = LoggingService.logger;
  static final String _baseUrl = '${AppConstants.baseApiUrl}/news';
  static const String _cacheKey = '${AppConstants.prefixStorageKey}news_cache';
  bool _isFetching = false;

  Future<List<News>> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      if (cachedString != null) {
        final json = jsonDecode(cachedString);
        final List data = json['data'] ?? [];
        return await compute(_parseNewsList, data);
      }
    } catch (e) {
      _logger.warning('Failed to load cached news: $e');
    }
    return [];
  }

  Future<List<News>> fetchNews({int page = 1, int limit = 10}) async {
    if (_isFetching) {
      _logger.info('Already fetching news, skipping this request.');
      return [];
    }
    _isFetching = true;

    try {
      String url = '$_baseUrl?page=$page&limit=$limit';
      
      _logger.info('Fetching news from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': AppConstants.userAgent},
      );

      if (response.statusCode == 200) {
        if (page == 1) {
          _logger.fine('Caching first page of news');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, response.body);
        }
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        _logger.info('News fetch page $page completed with ${data.length} items');
        return await compute(_parseNewsList, data);
      } else {
        _logger.severe(
          'Failed to load news (HTTP ${response.statusCode}) for URL: $url. Body: ${response.body}',
        );
        throw ApiException(message: 'Failed to load news', statusCode: response.statusCode);
      }
    } catch (e, st) {
      _logger.severe('Exception occurred while fetching news at page $page: $e\n$st');
      if (e is AppException) rethrow;
      throw NetworkException(message: 'Failed to load news', originalError: e, stackTrace: st);
    } finally {
      _isFetching = false;
    }
  }

  static List<News> _parseNewsList(List data) {
    return data.map((item) => News.fromJson(item as Map<String, dynamic>)).toList();
  }
}
