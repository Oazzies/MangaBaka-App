part of 'home_service.dart';

Future<List<TopGenre>> _fetchTopGenres(HomeService service, int limit) async {
  final headers = await service._authHeaders();
  if (headers == null) return const [];
  try {
    final genres = await service._api
        .withContext('home:top-genres')
        .getJson(
          ApiClient.uri(
            '${AppConstants.baseApiUrl}/my/series/discover/top-genres',
            {'limit': limit},
          ),
          operation: 'fetch top genres',
          parse: (json) {
            final results = json is Map ? json['results'] : null;
            if (results is! List) return const <TopGenre>[];
            return results
                .map(TopGenre.tryParse)
                .whereType<TopGenre>()
                .toList(growable: false);
          },
          headers: headers,
        );
    HomeService._logger.info(
      'HomeService top genres: ${genres.map((g) => g.name)}',
    );
    return genres;
  } catch (e) {
    HomeService._logger.warning('HomeService failed to fetch top genres: $e');
    return const [];
  }
}

Future<ForYouReadiness?> _fetchForYouReadiness(HomeService service) async {
  final headers = await service._authHeaders();
  if (headers == null) return null;

  try {
    final readiness = await service._api.getJson(
      ApiClient.uri(
        '${AppConstants.baseApiUrl}/my/series/recommendations/status',
      ),
      operation: 'probe For-You readiness',
      parse: (json) =>
          ForYouReadiness.fromJson((json as Map).cast<String, dynamic>()),
      headers: headers,
    );
    HomeService._logger.info(
      'For-You readiness: coldStart=${readiness.coldStart} '
      'stale=${readiness.profileStale} library=${readiness.libraryCount}',
    );
    return readiness;
  } catch (e) {
    HomeService._logger.warning('For-You readiness probe failed: $e');
    return null;
  }
}

Future<List<SeriesWork>> _fetchUpcomingWorks(
  HomeService service, {
  int page = 1,
  int perPage = 25,
}) async {
  try {
    final uri = ApiClient.uri('https://api.mangabaka.org/v1/works/upcoming', {
      'page': page,
      'per_page': perPage,
    });
    final works = await service._api
        .withContext('home:upcoming')
        .getJson(
          uri,
          operation: 'fetch upcoming works',
          parse: (json) => parseDataList(json, SeriesWork.fromJson),
        );
    HomeService._logger.info(
      'HomeService upcoming returned ${works.length} works',
    );
    return works;
  } catch (e) {
    HomeService._logger.warning(
      'HomeService failed to fetch upcoming works: $e',
    );
    return const [];
  }
}
