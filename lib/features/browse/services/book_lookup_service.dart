import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class BookLookupService {
  static final _logger = LoggingService.logger;
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const Duration _timeout =
      Duration(seconds: AppConstants.networkTimeoutSeconds);

  Future<String?> lookupTitleByIsbn(String isbn) async {
    _logger.info('Looking up book title for ISBN: $isbn');
    try {
      // First try Google Books API
      _logger.fine('Attempting Google Books API lookup for ISBN: $isbn');
      final googleResponse = await http
          .get(Uri.parse('$_baseUrl?q=isbn:$isbn'))
          .timeout(_timeout);

      if (googleResponse.statusCode == 200) {
        final data = json.decode(googleResponse.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          final items = data['items'] as List;
          if (items.isNotEmpty) {
            final volumeInfo = items.first['volumeInfo'];
            if (volumeInfo != null && volumeInfo['title'] != null) {
              final title = volumeInfo['title'] as String;
              _logger.info('Google Books found title: $title for ISBN: $isbn');
              return title;
            }
          }
        }
        _logger.fine('No results found for ISBN: $isbn in Google Books');
      } else {
        _logger.warning('Google Books API returned status code: ${googleResponse.statusCode} for ISBN: $isbn');
      }

      // Fallback to OpenLibrary API if Google Books fails or returns no results
      _logger.fine('Attempting OpenLibrary API lookup fallback for ISBN: $isbn');
      final openLibResponse = await http
          .get(Uri.parse('https://openlibrary.org/search.json?isbn=$isbn'))
          .timeout(_timeout);
      
      if (openLibResponse.statusCode == 200) {
        final data = json.decode(openLibResponse.body);
        if (data['docs'] != null && (data['docs'] as List).isNotEmpty) {
          final firstDoc = data['docs'][0];
          if (firstDoc['title'] != null) {
            final title = firstDoc['title'] as String;
            _logger.info('OpenLibrary found title: $title for ISBN: $isbn');
            return title;
          }
        }
        _logger.info('No results found for ISBN: $isbn in any API');
        return null; // Not found in either API
      } else {
        _logger.warning('OpenLibrary API returned status code: ${openLibResponse.statusCode} for ISBN: $isbn');
      }

      _logger.severe('All book lookup APIs failed for ISBN: $isbn');
      throw ApiException(
        message: 'Failed to lookup book. Google Books status: ${googleResponse.statusCode}, OpenLibrary status: ${openLibResponse.statusCode}', 
        statusCode: googleResponse.statusCode
      );
    } catch (e) {
      _logger.severe('Error during book lookup for ISBN: $isbn: $e');
      if (e is AppException) rethrow;
      throw NetworkException(message: 'Failed to lookup book by ISBN: $e');
    }
  }
}
