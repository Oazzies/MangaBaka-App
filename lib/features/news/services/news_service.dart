import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parsed via [compute]: long HTML bodies dropped frames on low-end devices.
class NewsService {
  static final _logger = LoggingService.logger;
  static final String _baseUrl = '${AppConstants.baseApiUrl}/news';
  static const String _cacheKey = '${AppConstants.prefixStorageKey}news_cache';

  final ApiClient _api;

  bool _isFetching = false;

  NewsService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'news', client: client);

  /// Never throws: a corrupt cache should cost the placeholder, not the tab.
  Future<List<News>> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return const [];
      return await _parse(jsonDecode(cached));
    } catch (e) {
      _logger.warning('Failed to load cached news: $e');
      return const [];
    }
  }

  Future<List<News>> fetchNews({int page = 1, int limit = 10}) async {
    if (_isFetching) {
      _logger.info('Already fetching news, skipping this request.');
      return const [];
    }
    _isFetching = true;

    try {
      final result = await _api.send(
        ApiClient.uri(_baseUrl, {'page': page, 'limit': limit}),
        operation: 'load news',
      );

      if (page == 1) {
        await _cacheFirstPage(result.body);
      }

      final news = await _parse(jsonDecode(result.body));
      _logger.info('News fetch page $page completed with ${news.length} items');
      return news;
    } finally {
      _isFetching = false;
    }
  }

  /// A write failure only costs next launch's placeholder, not the successful fetch.
  Future<void> _cacheFirstPage(String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      _logger.fine('Cached first page of news');
    } catch (e) {
      _logger.warning('Failed to cache news page: $e');
    }
  }

  Future<List<News>> _parse(dynamic json) =>
      compute(_parseNewsList, dataList(json));

  /// Runs on an isolate: must stay static and take only sendable data.
  static List<News> _parseNewsList(List<Map<String, dynamic>> data) {
    final out = <News>[];
    for (final item in data) {
      try {
        out.add(News.fromJson(item));
      } catch (e, st) {
        // Skip the malformed article rather than losing the whole page.
        developer.log(
          'Skipped malformed news item',
          name: 'NewsService',
          error: e,
          stackTrace: st,
        );
      }
    }
    return out;
  }

  void dispose() => _api.close();
}
