import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/features/series/models/series.dart';

class SeriesSearchService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/series/search';

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

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)'},
    );

    print("!!! API CALL MADE!!!");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data
          .map((item) => Series.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to search series');
    }
  }
}
