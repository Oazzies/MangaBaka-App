import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Fetching a single series by id, with a bounded in-memory cache.
///
/// Transport concerns (timeout, health reporting, failure translation) belong
/// to [ApiClient]; what stays here is the part specific to series: the cache,
/// the content-rating gate, and the status codes this endpoint gives distinct
/// meanings to.
mixin SeriesFetchMixin {
  final logger = LoggingService.logger;

  final Map<String, Series> _cache = {};

  /// Insertion-ordered, so `keys.first` is the oldest entry. 200 series is a
  /// few hundred KB at most and comfortably covers a browsing session without
  /// growing without bound on a long-lived process.
  static const int _maxCacheSize = 200;

  /// Overridable so a test can inject a client; defaults to the shared one.
  ApiClient get seriesApi => _defaultApi;
  static final ApiClient _defaultApi = ApiClient(healthContext: 'series');

  Map<String, Series> get cache => _cache;

  void precacheSeries(Series series) => _store(series.id, series);

  Future<Series> fetchSeries(String id) async {
    final cached = _cache[id];
    if (cached != null) {
      // Preferences can change after a series was cached, so the gate is
      // re-applied on the way out rather than only at fetch time.
      _assertAllowedByContentRating(cached, evictOnBlock: id);
      logger.fine('Returning cached series data for ID: $id');
      return cached;
    }

    final response = await seriesApi.send(
      ApiClient.uri('${AppConstants.baseApiUrl}/series/$id'),
      operation: 'fetch series',
      // 404 and 429 are meaningful answers from this endpoint rather than
      // generic failures, so they are handled here with their own messages.
      acceptedStatuses: const {200, 404, 429},
    );

    switch (response.statusCode) {
      case 404:
        logger.warning('Series not found: $id');
        throw ApiException(
          message: 'Series not found',
          statusCode: 404,
          responseBody: response.body,
          code: 'NOT_FOUND',
        );
      case 429:
        logger.warning('Rate limited while fetching series $id');
        throw ApiException(
          message: 'Too many requests. Please slow down.',
          statusCode: 429,
          responseBody: response.body,
          code: 'RATE_LIMITED',
        );
    }

    final series = ApiClient.decode(
      response.body,
      operation: 'fetch series',
      parse: (json) {
        final data = dataObject(json);
        if (data == null) {
          throw const FormatException('series response has no data object');
        }
        return Series.fromJson(data);
      },
    );

    _assertAllowedByContentRating(series);

    logger.info('Successfully fetched series: ${series.title} ($id)');
    _store(id, series);
    return series;
  }

  void _store(String id, Series series) {
    // Re-inserting refreshes recency, and replacing an existing id must not
    // evict an unrelated entry. Search results are precached by the page, so
    // this is also what keeps the cache bounded while browsing.
    _cache.remove(id);
    while (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[id] = series;
  }

  /// Blocks a series whose rating the user has chosen not to see.
  ///
  /// Modelled as a 403 so the UI treats it as "you may not view this" rather
  /// than a transport error worth retrying. An empty preference list means no
  /// preference has been recorded, which permits everything.
  void _assertAllowedByContentRating(Series series, {String? evictOnBlock}) {
    final prefs = SettingsManager().contentPreferences;
    if (prefs.isEmpty) return;
    if (prefs.contains(series.contentRating.toLowerCase())) return;

    if (evictOnBlock != null) _cache.remove(evictOnBlock);
    logger.warning(
      'Series ${series.title} (${series.id}) blocked due to content rating: '
      '${series.contentRating}',
    );
    throw ApiException(
      message: 'This content is filtered by your content rating settings.',
      statusCode: 403,
      code: 'CONTENT_FILTERED',
    );
  }
}
