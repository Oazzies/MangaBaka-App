import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';

/// Null is an ordinary "no match"; a failed request throws so the scanner can report it.
class BookLookupService {
  static final _logger = LoggingService.logger;
  static const String _identifiersPath = '/works/identifiers';

  final ApiClient _api;

  BookLookupService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'book-lookup', client: client);

  Future<String?> lookupTitleByIsbn(String isbn) async {
    _logger.info('Looking up title for ISBN: $isbn');

    final title = await _api.getJson<String?>(
      ApiClient.uri('${AppConstants.baseApiUrl}$_identifiersPath', {
        'identifier': isbn,
      }),
      operation: 'lookup book by ISBN',
      parse: (json) {
        final items = dataList(json);
        if (items.isEmpty) return null;
        final title = items.first['title'];
        return title is String && title.isNotEmpty ? title : null;
      },
    );

    if (title == null) {
      _logger.info('No results found for ISBN: $isbn');
    } else {
      _logger.info('Found title: $title for ISBN: $isbn');
    }
    return title;
  }

  void dispose() => _api.close();
}
