import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';

/// Why a barcode scan did not end on a series.
///
/// Each case names a localisation key so the controller can hand one straight
/// to the UI without knowing the wording — and so the reasons stay
/// distinguishable, which a bare null could not do.
enum BarcodeSearchFailure {
  /// The ISBN resolved to no title at all.
  notFound('barcode_not_found'),

  /// A title came back, but no series matched it even after cleaning.
  noSeriesFound('no_series_found_for'),

  /// The lookup request itself failed.
  lookupFailed('barcode_lookup_failed');

  final String messageKey;

  const BarcodeSearchFailure(this.messageKey);
}

/// Resolves a scanned ISBN to a series.
///
/// Two steps: the ISBN becomes a book title, and the title becomes a search.
/// A scanned title usually carries volume numbers and edition text that no
/// series is filed under, so a fruitless search is retried against a cleaned
/// version before giving up — the single most common reason a valid scan used
/// to come back empty.
///
/// Separate from `BrowseController` because none of it touches browse state:
/// it is handed a way to run a search and reports what happened.
class BarcodeSearch {
  static final _logger = LoggingService.logger;

  final BookLookupService? _injectedLookup;

  BarcodeSearch({BookLookupService? lookupService})
    : _injectedLookup = lookupService;

  /// Resolved per call rather than in the constructor: scanning is rare, and
  /// constructing a BrowseController must not require the lookup service to be
  /// registered.
  BookLookupService get _lookup =>
      _injectedLookup ?? getIt<BookLookupService>();

  /// Looks [isbn] up and runs [search] against the title it resolves to.
  ///
  /// [search] reports whether it matched anything. Returns null on success, or
  /// the reason it failed.
  Future<BarcodeSearchFailure?> run(
    String isbn, {
    required Future<bool> Function(String title) search,
  }) async {
    _logger.info('Handling barcode scan for ISBN: $isbn');

    final String? title;
    try {
      title = await _lookup.lookupTitleByIsbn(isbn);
    } catch (e, st) {
      // Only the lookup is wrapped: a failure inside `search` is a search bug
      // and should surface as one rather than as a lookup failure.
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
