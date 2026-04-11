import 'package:http/http.dart' as http;
import 'dart:convert';

class SeriesService {
  static Future<Map<String, dynamic>> fetchSeries(int id) async {
    final url = Uri.parse("https://api.mangabaka.dev/v1/series/$id");
    final response = await http.get(url);

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception("Failed to load series");
    }
  }
}