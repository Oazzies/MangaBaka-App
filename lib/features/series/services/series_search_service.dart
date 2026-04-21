import 'dart:convert';
import 'dart:io';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/series/models/series.dart';

class SeriesSearchService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/series/search';
  final _logger = LoggingService.logger;

  Future<List<Series>> searchSeriesByName(
    String query, {
    String? sortBy,
    String? type,
    Map<String, dynamic>? extraParams,
  }) async {
    String url = '$_baseUrl?q=${Uri.encodeComponent(query)}';
    if (sortBy != null) {
      url += '&sort_by=$sortBy';
    }
    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }
    if (extraParams != null) {
      extraParams.forEach((key, value) {
        url += '&$key=$value';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        return data
            .map((item) => Series.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _logger.severe(
            'Failed to search series. Status code: ${response.statusCode}, body: ${response.body}');
        throw Exception(
            'Failed to search series. Status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      _logger.severe('Failed to search series due to a network error: $e');
      throw Exception('Failed to search series. Please check your network connection.');
    } catch (e) {
      _logger.severe('An unexpected error occurred during series search: $e');
      throw Exception('An unexpected error occurred while searching for series.');
    }
  }
}
