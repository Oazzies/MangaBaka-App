import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class BookLookupService {
  static final _logger = LoggingService.logger;
  static const String _identifiersPath = '/works/identifiers';
  static const Duration _timeout =
      Duration(seconds: AppConstants.networkTimeoutSeconds);

  Future<String?> lookupTitleByIsbn(String isbn) async {
    _logger.info('Looking up title for ISBN: $isbn');
    final uri = Uri.parse('${AppConstants.baseApiUrl}$_identifiersPath')
        .replace(queryParameters: {'identifier': isbn});
    try {
      final response = await http
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data'] as List?;
        if (items != null && items.isNotEmpty) {
          final title = items.first['title'] as String?;
          if (title != null) {
            _logger.info('Found title: $title for ISBN: $isbn');
            return title;
          }
        }
        _logger.info('No results found for ISBN: $isbn');
        return null;
      }

      _logger.warning('Works identifiers API returned status: ${response.statusCode} for ISBN: $isbn');
      throw ApiException(
        message: 'Failed to lookup book by ISBN',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e) {
      _logger.severe('Error during book lookup for ISBN: $isbn: $e');
      if (e is AppException) rethrow;
      throw NetworkException(message: 'Failed to lookup book by ISBN: $e');
    }
  }
}
