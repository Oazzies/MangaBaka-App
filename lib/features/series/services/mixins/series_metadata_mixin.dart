import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/related_series.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_title_enricher.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// Every fetch degrades to an empty list: a failed sub-resource must not take down a loaded detail page.
mixin SeriesMetadataMixin {
  final _logger = LoggingService.logger;

  /// Overridden in tests to inject a client.
  ApiClient get metadataApi => _defaultApi;

  SeriesTitleEnricher get titleEnricher => SeriesTitleEnricher.shared;
  static final ApiClient _defaultApi = ApiClient(healthContext: 'series-meta');

  Future<List<SeriesLink>> fetchSeriesLinks(String id) =>
      _fetchList(id, 'links', SeriesLink.fromJson);

  Future<List<SeriesCover>> fetchSeriesCovers(String id) =>
      _fetchList(id, 'images', SeriesCover.fromJson, params: {'limit': 50});

  Future<List<News>> fetchSeriesNews(String id) =>
      _fetchList(id, 'news', News.fromJson);

  Future<List<SeriesCollection>> fetchSeriesCollections(String id) =>
      _fetchList(id, 'collections', SeriesCollection.fromJson);

  Future<List<SeriesWork>> fetchSeriesWorks(String id) =>
      _fetchList(id, 'works', SeriesWork.fromJson);

  /// Not `/related`: it is deprecated and returns relation buckets, not a `data` array.
  Future<List<RelatedSeries>> fetchSeriesRelated(String id) async =>
      _filterByContentRating(
        await _fetchList(
          id,
          'relationships',
          RelatedSeries.fromJson,
          params: {'limit': 50},
        ),
        (r) => r.series,
      );

  /// Items arrive wrapped (`{series: {...}, score: …}`) in the lean v2 shape.
  Future<List<Series>> fetchSeriesSimilar(String id) async =>
      _allowedByContentRating(
        await titleEnricher.canonicalize(
          await _fetchList(id, 'similar', (item) {
            final nested = item['series'];
            if (nested is! Map) return null;
            return Series.fromSimilarJson(nested.cast<String, dynamic>());
          }, params: {'limit': 20}),
        ),
      );

  Future<List<Series>> fetchSeriesReadersAlsoLike(String id) async {
    final prefs = SettingsManager().contentPreferences;
    return _allowedByContentRating(
      await titleEnricher.canonicalize(
        await _fetchList(
          id,
          'readers-also-like',
          (item) {
            final nested = item['series'];
            if (nested is! Map) return null;
            return Series.fromSimilarJson(nested.cast<String, dynamic>());
          },
          params: {'limit': 24, 'content_rating': prefs},
          base: AppConstants.baseApiUrlV2,
        ),
      ),
    );
  }

  Future<List<T>> _fetchList<T>(
    String id,
    String path,
    T? Function(Map<String, dynamic> item) fromJson, {
    Map<String, dynamic>? params,
    String base = AppConstants.baseApiUrl,
  }) async {
    try {
      return await metadataApi.getJson(
        ApiClient.uri('$base/series/$id/$path', params),
        operation: 'fetch series $path',
        parse: (json) => parseDataList(json, (item) {
          try {
            return fromJson(item);
          } catch (e) {
            _logger.fine('Skipping malformed $path item for $id: $e');
            return null;
          }
        }),
      );
    } catch (e) {
      _logger.warning('Error fetching $path for $id: $e');
      return const [];
    }
  }

  List<Series> _allowedByContentRating(List<Series> series) =>
      _filterByContentRating(series, (s) => s);

  List<T> _filterByContentRating<T>(
    List<T> items,
    Series Function(T) seriesOf,
  ) {
    final prefs = SettingsManager().contentPreferences;
    if (prefs.isEmpty) return items;
    return items
        .where(
          (item) => prefs.contains(seriesOf(item).contentRating.toLowerCase()),
        )
        .toList();
  }
}
