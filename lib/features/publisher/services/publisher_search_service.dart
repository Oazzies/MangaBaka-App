import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// The series shelves on a publisher's page, mirroring the web page.
enum PublisherShelf { newest, popular, highestRated, trending, hiddenGems }

/// Reads the v2 `/publishers` endpoints.
///
/// Request plumbing — timeout, User-Agent, status handling, backend-health
/// reporting and failure translation — lives in [ApiClient]; what remains here
/// is the parameter shaping and JSON mapping specific to publishers.
class PublisherSearchService {
  static final String _base = '${AppConstants.baseApiUrlV2}/publishers';

  /// Values `sort_by` accepts on the list endpoint (anything else is a 400).
  static const String sortNameAsc = 'name_asc';
  static const String sortNameDesc = 'name_desc';
  static const String sortSeriesCountDesc = 'series_count_desc';
  static const String sortSeriesCountAsc = 'series_count_asc';
  static const String sortNewest = 'created_at_desc';

  /// Parameters the list endpoint understands. Anything else in a caller's
  /// map is dropped rather than forwarded, so a stray UI-only key cannot turn
  /// into a 400 (v2 rejects unknown parameters).
  static const Set<String> _allowedSearchKeys = {
    'q',
    'page',
    'limit',
    'sort_by',
  };

  final ApiClient _api;

  PublisherSearchService({http.Client? client, ApiClient? api})
      : _api = api ??
            ApiClient(healthContext: 'publisher-search', client: client);

  Future<List<Publisher>> searchPublishers({
    String? query,
    int? page,
    int? limit,
    String? sortBy,
  }) async {
    final result = await search({
      'q': query,
      'page': page,
      'limit': limit,
      'sort_by': sortBy,
    });
    return result.publishers;
  }

  Future<PublisherSearchResult> search(Map<String, dynamic> params) {
    final cleaned = <String, dynamic>{
      for (final entry in params.entries)
        if (_allowedSearchKeys.contains(entry.key)) entry.key: entry.value,
    };

    return _api.getJson(
      ApiClient.uri(_base, cleaned),
      operation: 'search publishers',
      parse: (json) => PublisherSearchResult(
        publishers: parseDataList(json, Publisher.fromJson),
        total: totalCount(json),
      ),
    );
  }

  /// Full record: aliases, links, parent, imprints, description.
  Future<Publisher> getPublisher(String id) {
    return _api.getJson(
      ApiClient.uri('$_base/$id'),
      operation: 'fetch publisher details',
      parse: (json) {
        final data = dataObject(json);
        if (data == null) {
          throw const FormatException('publisher response has no data object');
        }
        return Publisher.fromJson(data);
      },
    );
  }

  Future<List<SimilarPublisher>> getSimilar(String id) {
    return _api.getJson(
      ApiClient.uri('$_base/$id/similar'),
      operation: 'fetch similar publishers',
      parse: (json) => parseDataList(json, SimilarPublisher.fromJson),
    );
  }

  Future<PublisherStats> getStats(String id) {
    return _api.getJson(
      ApiClient.uri('$_base/$id/stats'),
      operation: 'fetch publisher stats',
      parse: (json) {
        final data = dataObject(json);
        if (data == null) {
          throw const FormatException('stats response has no data object');
        }
        return PublisherStats.fromJson(data);
      },
    );
  }

  /// One shelf of a publisher's series. Content-rating preferences apply, as
  /// on every other discovery surface.
  Future<List<Series>> getShelf(
    String publisherId,
    PublisherShelf shelf, {
    int limit = 20,
  }) {
    final prefs = SettingsManager().contentPreferences
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    final Uri uri;
    if (shelf == PublisherShelf.hiddenGems) {
      uri = ApiClient.uri('${AppConstants.baseApiUrlV2}/series/discover/hidden-gems', {
        'publisher_id': publisherId,
        'limit': limit,
        'not_content_rating': ContentRatingFilter.excludedByPreference(),
      });
    } else {
      uri = ApiClient.uri('${AppConstants.baseApiUrlV2}/series/search', {
        'publisher_id': publisherId,
        'limit': limit,
        'sort_by': switch (shelf) {
          PublisherShelf.newest => 'published_start_date_desc',
          PublisherShelf.popular => 'popularity_desc',
          PublisherShelf.highestRated => 'score_desc',
          _ => 'trending_7d',
        },
        // Unrated stubs would otherwise crowd these two shelves.
        if (shelf == PublisherShelf.highestRated) 'rating_lower': 1,
        if (prefs.isNotEmpty) 'content_rating': prefs,
      });
    }
    return _api.getJson(
      uri,
      operation: 'fetch publisher series',
      parse: (json) => parseDataList(json, Series.fromSimilarJson),
    );
  }

  void dispose() => _api.close();
}

class PublisherSearchResult {
  final List<Publisher> publishers;
  final int total;

  PublisherSearchResult({required this.publishers, required this.total});
}
