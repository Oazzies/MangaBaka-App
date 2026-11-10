import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';

/// Resolves a scanned barcode to a series title via `/works/identifiers`.
///
/// Backs the barcode scanner: the title it returns is fed straight into the
/// search field, so "no match" (null) is an ordinary outcome and distinct from
/// a failed request, which propagates so the scanner can say the lookup could
/// not be completed.
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
