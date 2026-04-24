import 'dart:convert';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/news/models/news.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  static final _logger = LoggingService.logger;
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/news';
  static const String _cacheKey = 'mb_news_cache';
  bool _isFetching = false;

  Future<List<News>> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      if (cachedString != null) {
        final json = jsonDecode(cachedString);
        final List data = json['data'] ?? [];
        return data.map((item) => News.fromJson(item as Map<String, dynamic>)).toList();
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
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
      );

      print("News API");

      if (response.statusCode == 200) {
        if (page == 1) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, response.body);
        }
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        return data
            .map((item) => News.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _logger.severe(
          'Failed to load news: ${response.statusCode} ${response.body}',
        );
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Failed to load news: $e');
      throw Exception('Failed to load news.');
    } finally {
      _isFetching = false;
    }
  }
}
