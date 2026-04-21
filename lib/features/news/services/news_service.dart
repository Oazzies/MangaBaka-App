import 'dart:convert';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/news/models/news.dart';

class NewsService {
  static final _logger = LoggingService.logger;
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/news';
  bool _isFetching = false;

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

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        return data
            .map((item) => News.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _logger.severe(
            'Failed to load news: ${response.statusCode} ${response.body}');
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