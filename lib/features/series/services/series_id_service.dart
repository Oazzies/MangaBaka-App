import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SeriesService {
  static final _logger = LoggingService.logger;

  static Future<Series> fetchSeries(String id) async {
    try {
      final url = Uri.parse("https://api.mangabaka.dev/v1/series/$id");
      final response = await http.get(
        url,
        headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Series.fromJson(data['data']);
      } else {
        _logger.severe(
            'Failed to load series: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load series: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Failed to load series: $e');
      throw Exception('Failed to load series.');
    }
  }
}