import 'dart:convert';
import 'package:http/http.dart' as http;

class SeriesSearchService {
  static const String _baseUrl = 'https://api.mangabaka.dev/v1/series/search';

  Future<List<Map<String, dynamic>>> searchSeriesByName(String query) async {
    final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to search series');
    }
  }
}