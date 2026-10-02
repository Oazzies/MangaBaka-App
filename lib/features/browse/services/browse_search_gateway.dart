import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/utils/series_local_sort.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// One page of browse results.
class BrowsePage<T> {
  final List<T> items;

  /// Total matches, as far as the server reports or the client can infer.
  final int total;

  /// True when [total] is a placeholder rather than a real count — the server
  /// returned none and the page was full, so all that is known is "at least
  /// this many". The UI shows it as "1000+".
  final bool isTotalCapped;

  /// True when a further page is worth requesting.
  final bool hasMore;

  const BrowsePage({
    required this.items,
    required this.total,
    required this.hasMore,
    this.isTotalCapped = false,
  });
}

/// Turns a browse query into a page of results, per result type.
///
/// The three types share a query and a page number but almost nothing else:
/// series come from the search endpoint, publishers from their own, and staff
/// are derived from series credits because there is no staff endpoint. Each
/// used to be a `_fetch…Results` method on `BrowseController` that reached
/// into its state and wrote back to it directly.
///
/// Everything here is stateless: hand it a query and get a page. The
/// controller keeps the accumulated results, the loading flags and the
/// generation guard.
class BrowseSearchGateway {
  static final _logger = LoggingService.logger;

  /// Placeholder total for an uncapped result set. The API stops reporting
  /// real totals past a point, and an honest "lots" beats a wrong number.
  static const int cappedTotal = 1000;

  final SeriesSearchService _series;
  final PublisherSearchService _publishers;

  BrowseSearchGateway({
    SeriesSearchService? seriesSearchService,
    PublisherSearchService? publisherSearchService,
  })  : _series = seriesSearchService ?? getIt<SeriesSearchService>(),
        _publishers = publisherSearchService ?? getIt<PublisherSearchService>();

  Future<BrowsePage<Series>> fetchSeries({
    required String query,
    required int page,
    required SearchFilters filters,
    required int alreadyLoaded,
  }) async {
    final excludeUserId = _excludeUserId();

    final result = await _series.searchSeries(
      query,
      sortBy: filters.sortBy,
      type: filters.type.isNotEmpty ? filters.type.first : null,
      extraParams: {
        'page': page,
        'limit': AppConstants.defaultPageLimit,
        ...filters.toMap(),
        if (excludeUserId != null) 'exclude_user_library': excludeUserId,
      },
    );

    final items = result.series;

    // The API prioritises relevance whenever a query is present and ignores
    // the requested sort, so it is reapplied per page.
    if (query.isNotEmpty) {
      SeriesLocalSort.apply(items, filters.sortBy);
    }

    final total = _resolveTotal(
      reported: result.total,
      pageSize: items.length,
      alreadyLoaded: alreadyLoaded,
    );

    _logger.info(
      'Fetched ${items.length} series results for page $page '
      '(Total: ${total.value})',
    );

    return BrowsePage(
      items: items,
      total: total.value,
      isTotalCapped: total.isCapped,
      hasMore: items.length == AppConstants.defaultPageLimit,
    );
  }

  Future<BrowsePage<Publisher>> fetchPublishers({
    required String query,
    required int page,
    required int alreadyLoaded,
    String? sortBy,
  }) async {
    final trimmed = query.trim();
    final result = await _publishers.search({
      if (trimmed.isNotEmpty) 'q': trimmed,
      'page': page,
      'limit': AppConstants.defaultPageLimit,
      // Browsing with no query lists the biggest publishers first; a search
      // keeps the API's relevance order unless the user picked another.
      if (sortBy != null)
        'sort_by': sortBy
      else if (trimmed.isEmpty)
        'sort_by': PublisherSearchService.sortSeriesCountDesc,
    });

    final items = result.publishers;
    _logger.info(
      'Fetched ${items.length} publisher results for page $page',
    );

    return BrowsePage(
      items: items,
      total: result.total > 0 ? result.total : alreadyLoaded + items.length,
      hasMore: items.length == AppConstants.defaultPageLimit,
    );
  }

  /// Staff are derived from the credits on series matching [query].
  ///
  /// The page size therefore describes *series* fetched, not people found —
  /// which is why [BrowsePage.hasMore] is judged on the underlying series page
  /// and the total is left to the caller, who knows how many unique people
  /// have accumulated across pages.
  Future<BrowsePage<Staff>> fetchStaff({
    required String query,
    required int page,
    required SearchFilters filters,
  }) async {
    final series = await _series.searchSeriesByName(
      '',
      extraParams: {
        'staff': query,
        'page': page,
        'limit': AppConstants.defaultPageLimit,
        ...filters.toMap(),
      },
    );

    final staff = StaffAggregator.fromSeries(series, query);
    _logger.info(
      'Fetched ${staff.length} staff results extracted from '
      '${series.length} series for page $page',
    );

    return BrowsePage(
      items: staff,
      total: staff.length,
      hasMore: series.length == AppConstants.defaultPageLimit,
    );
  }

  /// Reconciles the server's total with what the page actually contained.
  ///
  /// The endpoint sometimes reports 0 alongside real data. A short page means
  /// the end has been reached and the true total can be counted; a full page
  /// means there is more, and only a floor can be given.
  static ({int value, bool isCapped}) _resolveTotal({
    required int reported,
    required int pageSize,
    required int alreadyLoaded,
  }) {
    if (reported > 0) return (value: reported, isCapped: false);
    if (pageSize < AppConstants.defaultPageLimit) {
      return (value: alreadyLoaded + pageSize, isCapped: false);
    }
    return (value: cappedTotal, isCapped: true);
  }

  /// The current user's id when "hide library series" is on, for the API's
  /// `exclude_user_library` filter. Null whenever the setting is off, the user
  /// is logged out, or no profile has been cached yet.
  String? _excludeUserId() {
    if (!SettingsManager().hideLibrarySeriesInBrowse) return null;
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return null;

    // The endpoint takes the id unhyphenated.
    final userId = auth.cachedProfile?.id.replaceAll('-', '') ?? '';
    if (userId.isEmpty) return null;
    _logger.fine('Hiding library series for user: $userId');
    return userId;
  }
}
