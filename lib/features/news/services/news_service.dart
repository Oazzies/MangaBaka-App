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

/// Reads the `/news` feed, with the first page mirrored to disk so the news
/// tab has something to show before the network answers.
///
/// Parsing runs on a background isolate via [compute]: a page of news carries
/// long HTML bodies, and decoding them on the UI thread dropped frames on
/// low-end devices.
class NewsService {
  static final _logger = LoggingService.logger;
  static final String _baseUrl = '${AppConstants.baseApiUrl}/news';
  static const String _cacheKey = '${AppConstants.prefixStorageKey}news_cache';

  final ApiClient _api;

  /// Guards against overlapping fetches — the news tab can fire a refresh and
  /// a pagination request at nearly the same moment.
  bool _isFetching = false;

  NewsService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'news', client: client);

  /// The last cached first page, or an empty list when there is none.
  ///
  /// Never throws: this runs on the way to showing the screen, and a corrupt
  /// cache should cost the placeholder, not the tab.
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

  /// Fetches a page of news.
  ///
  /// Returns an empty list when a fetch is already in flight rather than
  /// queueing a duplicate. Failures propagate as [ApiException] /
  /// [NetworkException] so the caller can show a retry affordance.
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

  /// Mirrors the first page to disk. A write failure only costs the offline
  /// placeholder on the next launch, so it must not fail the fetch that
  /// already succeeded.
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

  /// Runs on a background isolate — must stay a top-level/static function
  /// operating only on data that can cross the isolate boundary.
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
