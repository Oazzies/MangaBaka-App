import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/features/home/models/for_you_readiness.dart';
import 'package:mangabaka_app/features/home/models/top_genre_rail.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/services/series_title_enricher.dart';

export 'package:mangabaka_app/features/home/models/for_you_readiness.dart';
export 'package:mangabaka_app/features/home/models/top_genre_rail.dart';

part 'home_personalization_part.dart';

/// Rails read the lean v2 series shape, which [Series.fromSimilarJson] already normalises.
/// Every method degrades to empty rather than throwing: one dead rail must not blank Home.
class HomeService {
  static final _logger = LoggingService.logger;

  static const String _v2Base = 'https://api.mangabaka.org/v2';

  final ApiClient _api;
  final SeriesTitleEnricher _titles;

  HomeService({
    http.Client? client,
    ApiClient? api,
    SeriesTitleEnricher? titles,
  }) : _api = api ?? ApiClient(healthContext: 'home', client: client),
       _titles = titles ?? SeriesTitleEnricher.shared;

  /// [SettingsManager.contentPreferences] is an allow-list, so it maps onto `content_rating`.
  Map<String, dynamic> _contentParams() {
    final allowed = SettingsManager().contentPreferences
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (allowed.isEmpty) return const {};
    return {'content_rating': allowed};
  }

  Uri _v2Uri(String path, Map<String, dynamic> params) =>
      ApiClient.uri('$_v2Base$path', {...params, ..._contentParams()});

  Future<List<Series>> fetchRising({int limit = 20, int windowDays = 7}) {
    return _fetchRail(
      _v2Uri('/series/discover/rising', {
        'limit': limit,
        'window_days': windowDays,
      }),
      'rising',
    );
  }

  /// This endpoint accepts the deny-list `not_content_rating`, unlike the other rails' allow-list.
  Future<List<Series>> fetchHiddenGems({int limit = 20}) {
    return _fetchRail(
      ApiClient.uri('$_v2Base/series/discover/hidden-gems', {
        'limit': limit,
        'not_content_rating': ContentRatingFilter.excludedByPreference(),
      }),
      'hidden gems',
    );
  }

  /// No `discover/trending` endpoint exists; like the web, this uses the `trending_7d/30d` sorts.
  Future<List<Series>> fetchTrending({
    String? type,
    int windowDays = 7,
    int limit = 20,
  }) {
    return _fetchRail(
      _v2Uri('/series/search', {
        'sort_by': windowDays == 30 ? 'trending_30d' : 'trending_7d',
        'limit': limit,
        'type': type,
      }),
      'trending',
    );
  }

  /// The rating floor keeps unrated stubs from crowding the rail.
  Future<List<Series>> fetchNewReleases({int limit = 20}) {
    final lower = DateTime.now().toUtc().subtract(const Duration(days: 365));
    return _fetchRail(
      _v2Uri('/series/search', {
        'sort_by': 'published_start_date_desc',
        'published_start_date_lower': _isoDate(lower),
        'rating_lower': 1,
        'limit': limit,
      }),
      'new releases',
    );
  }

  Future<List<Series>> fetchForYou({int limit = 20}) async {
    final headers = await _authHeaders();
    if (headers == null) return const [];

    try {
      final uri = ApiClient.uri(
        '${AppConstants.baseApiUrl}/my/series/recommendations',
        {'limit': limit, ..._contentParams()},
      );
      final raw = await _api
          .withContext('home:for-you')
          .getJson(
            uri,
            operation: 'fetch for-you',
            parse: (json) {
              final list = (json is Map)
                  ? (json['results'] ?? json['data'])
                  : null;
              if (list is! List) return const <Series>[];
              // One malformed recommendation must not empty the whole rail.
              final parsed = <Series>[];
              for (final m in list.whereType<Map>()) {
                try {
                  parsed.add(
                    Series.fromRecommendationJson(m.cast<String, dynamic>()),
                  );
                } catch (e) {
                  _logger.fine('Skipping malformed recommendation: $e');
                }
              }
              return parsed;
            },
            headers: headers,
          );
      final series = await _titles.canonicalize(raw);
      _logger.info('HomeService for-you returned ${series.length} series');
      final dismissed = SettingsManager().dismissedRecommendations.toSet();
      if (dismissed.isEmpty) return series;
      return series
          .where((s) => !dismissed.contains(s.id))
          .toList(growable: false);
    } catch (e) {
      _logger.warning('HomeService failed to fetch for-you: $e');
      return const [];
    }
  }

  Future<Map<String, String>?> _authHeaders() async {
    final auth = getIt<ProfileAuthService>();
    if (!auth.isLoggedIn) return null;
    try {
      final token = await auth.getValidAccessToken();
      return {'Authorization': 'Bearer $token'};
    } catch (e) {
      _logger.warning('Could not obtain access token for Home rail: $e');
      return null;
    }
  }

  Future<List<Series>> _fetchRail(
    Uri uri,
    String label, {
    Map<String, String>? headers,
  }) async {
    try {
      final raw = await _api
          .withContext('home:$label')
          .getJson(
            uri,
            operation: 'fetch $label',
            parse: (json) => parseDataList(json, Series.fromSimilarJson),
            headers: headers,
          );
      final series = await _titles.canonicalize(raw);
      _logger.info('HomeService $label returned ${series.length} series');
      return series;
    } catch (e) {
      _logger.warning('HomeService failed to fetch $label: $e');
      return const [];
    }
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The (beta) endpoint answers with `results`, not `data`.
  Future<List<TopGenre>> fetchTopGenres({int limit = 3}) =>
      _fetchTopGenres(this, limit);

  Future<List<Series>> fetchTopInGenre(int tagId, {int limit = 20}) {
    return _fetchRail(
      _v2Uri('/series/search', {
        'tag': tagId,
        'sort_by': 'score_desc',
        // Unrated series sort unpredictably under a score sort.
        'rating_lower': 1,
        'limit': limit,
      }),
      'top in genre $tagId',
    );
  }

  Future<List<TopGenreRail>> fetchTopGenreRails({int genres = 3}) async {
    final top = await fetchTopGenres(limit: genres);
    if (top.isEmpty) return const [];
    final lists = await Future.wait([
      for (final g in top) fetchTopInGenre(g.tagId),
    ]);
    return [
      for (var i = 0; i < top.length; i++)
        if (lists[i].isNotEmpty) TopGenreRail(top[i], lists[i]),
    ];
  }

  /// Null means hide the rail without explanation: logged out, or the probe failed.
  Future<ForYouReadiness?> fetchForYouReadiness() =>
      _fetchForYouReadiness(this);

  Future<List<SeriesWork>> fetchUpcomingWorks({
    int page = 1,
    int perPage = 25,
  }) => _fetchUpcomingWorks(this, page: page, perPage: perPage);

  void dispose() => _api.close();
}
