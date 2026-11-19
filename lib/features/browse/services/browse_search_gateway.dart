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

class BrowsePage<T> {
  final List<T> items;

  final int total;

  /// [total] is a floor, not a count: the server gave none and the page was full ("1000+").
  final bool isTotalCapped;

  final bool hasMore;

  const BrowsePage({
    required this.items,
    required this.total,
    required this.hasMore,
    this.isTotalCapped = false,
  });
}

class BrowseSearchGateway {
  static final _logger = LoggingService.logger;

  /// The API stops reporting real totals past a point; an honest "lots" beats a wrong number.
  static const int cappedTotal = 1000;

  final SeriesSearchService _series;
  final PublisherSearchService _publishers;

  BrowseSearchGateway({
    SeriesSearchService? seriesSearchService,
    PublisherSearchService? publisherSearchService,
  }) : _series = seriesSearchService ?? getIt<SeriesSearchService>(),
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

    // With a query the API sorts by relevance and ignores `sort_by`, so sort each page locally.
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
      if (sortBy != null)
        'sort_by': sortBy
      else if (trimmed.isEmpty)
        'sort_by': PublisherSearchService.sortSeriesCountDesc,
    });

    final items = result.publishers;
    _logger.info('Fetched ${items.length} publisher results for page $page');

    return BrowsePage(
      items: items,
      total: result.total > 0 ? result.total : alreadyLoaded + items.length,
      hasMore: items.length == AppConstants.defaultPageLimit,
    );
  }

  /// There is no staff endpoint: staff come from series credits, so page size counts series.
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

  /// The endpoint sometimes reports 0 alongside real data; a full page can then only give a floor.
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
