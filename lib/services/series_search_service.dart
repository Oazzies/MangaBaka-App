import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/models/series.dart';

class SeriesSearchService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/series/search';

  Future<List<Series>> searchSeriesByName(String query) async {
    final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}');

    final response = await http.get(
      url,
      headers: {'User-Agent': 'MangaBakaApp/0.0 (oazziesmail@gmail.com)'},
    );

    print("!!! API CALL MADE!!!");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((item) => Series.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to search series');
    }
  }
}