import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';

class BookLookupService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<String?> lookupTitleByIsbn(String isbn) async {
    try {
      // First try Google Books API
      final googleResponse = await http.get(Uri.parse('$_baseUrl?q=isbn:$isbn'));

      if (googleResponse.statusCode == 200) {
        final data = json.decode(googleResponse.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          final items = data['items'] as List;
          if (items.isNotEmpty) {
            final volumeInfo = items.first['volumeInfo'];
            if (volumeInfo != null && volumeInfo['title'] != null) {
              return volumeInfo['title'] as String;
            }
          }
        }
      }

      // Fallback to OpenLibrary API if Google Books fails or returns no results
      final openLibResponse = await http.get(Uri.parse('https://openlibrary.org/search.json?isbn=$isbn'));
      
      if (openLibResponse.statusCode == 200) {
        final data = json.decode(openLibResponse.body);
        if (data['docs'] != null && (data['docs'] as List).isNotEmpty) {
          final firstDoc = data['docs'][0];
          if (firstDoc['title'] != null) {
            return firstDoc['title'] as String;
          }
        }
        return null; // Not found in either API
      }

      throw ApiException(
        message: 'Failed to lookup book. Google Books status: ${googleResponse.statusCode}, OpenLibrary status: ${openLibResponse.statusCode}', 
        statusCode: googleResponse.statusCode
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: 'Failed to lookup book by ISBN: $e');
    }
  }
}
