import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_title_enricher.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// The optional sub-resources of a series: links, covers, related titles,
/// news, collections, works and similar titles.
///
/// These populate the tabs of the series detail screen and are all *additive*:
/// each one fills a section that is simply absent when the fetch fails. So
/// every method here degrades to an empty list and logs, rather than
/// propagating — a failed "similar titles" call must not take down a detail
/// page whose main content already loaded.
///
/// The seven methods were previously seven copies of the same request block
/// differing only in path and model; they now share [_fetchList].
mixin SeriesMetadataMixin {
  final _logger = LoggingService.logger;

  /// Overridable so a test can inject a client; defaults to the shared one.
  ApiClient get metadataApi => _defaultApi;

  /// Overridable like [metadataApi]; resolves the canonical titles of the
  /// v2 lists ("similar", "readers also like").
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

  /// Uses `/relationships`: the older `/related` is deprecated and answers
  /// with an object of relation buckets rather than a `data` array, which
  /// [_fetchList] would read as empty. Each item wraps the series.
  Future<List<Series>> fetchSeriesRelated(String id) async =>
      _allowedByContentRating(
        await _fetchList(id, 'relationships', (item) {
          final nested = item['series'];
          if (nested is! Map) return null;
          return Series.fromJson(nested.cast<String, dynamic>());
        }, params: {'limit': 50}),
      );

  /// Similar titles come back wrapped (`{series: {...}, score: …}`) and in the
  /// lean v2 shape, hence the different unwrap and constructor.
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

  /// Collaborative-filtering recommendations: titles that readers of this one
  /// also have in their libraries.
  ///
  /// Unlike [fetchSeriesSimilar], which ranks by shared tags and creators,
  /// this ranks by shared *readers*, so the two lists surface different
  /// titles. v2-only; the lean shape (titles as an array) is the one
  /// [Series.fromSimilarJson] already normalises. Ordered best-first by the
  /// server.
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

  /// Fetches `/series/{id}/{path}` and maps its `data` array through
  /// [fromJson], skipping items that fail to parse.
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

  /// Drops series the user has chosen not to see. An empty preference list
  /// means no preference has been recorded, which permits everything.
  List<Series> _allowedByContentRating(List<Series> series) {
    final prefs = SettingsManager().contentPreferences;
    if (prefs.isEmpty) return series;
    return series
        .where((s) => prefs.contains(s.contentRating.toLowerCase()))
        .toList();
  }
}
