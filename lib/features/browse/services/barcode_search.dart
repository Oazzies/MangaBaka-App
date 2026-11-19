import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';

enum BarcodeSearchFailure {
  notFound('barcode_not_found'),

  noSeriesFound('no_series_found_for'),

  lookupFailed('barcode_lookup_failed');

  final String messageKey;

  const BarcodeSearchFailure(this.messageKey);
}

/// Scanned titles carry volume/edition text no series is filed under, so a miss retries cleaned.
class BarcodeSearch {
  static final _logger = LoggingService.logger;

  final BookLookupService? _injectedLookup;

  BarcodeSearch({BookLookupService? lookupService})
    : _injectedLookup = lookupService;

  /// Per call: constructing a BrowseController must not require the lookup service registered.
  BookLookupService get _lookup =>
      _injectedLookup ?? getIt<BookLookupService>();

  Future<BarcodeSearchFailure?> run(
    String isbn, {
    required Future<bool> Function(String title) search,
  }) async {
    _logger.info('Handling barcode scan for ISBN: $isbn');

    final String? title;
    try {
      title = await _lookup.lookupTitleByIsbn(isbn);
    } catch (e, st) {
      // Only the lookup is wrapped: a failure in `search` is a search bug, not a lookup failure.
      _logger.severe('Error handling barcode scan for ISBN $isbn', e, st);
      return BarcodeSearchFailure.lookupFailed;
    }

    if (title == null || title.isEmpty) {
      _logger.warning('No title found for ISBN: $isbn');
      return BarcodeSearchFailure.notFound;
    }

    _logger.info('Found title from ISBN: $title');
    if (await search(title)) return null;

    final cleaned = BrowseHelpers.cleanTitle(title);
    if (cleaned != title && cleaned.isNotEmpty) {
      _logger.info('No results for raw title, trying cleaned title: $cleaned');
      if (await search(cleaned)) return null;
    }

    _logger.warning(
      'No series found for title associated with ISBN: $isbn (Title: $title)',
    );
    return BarcodeSearchFailure.noSeriesFound;
  }
}
