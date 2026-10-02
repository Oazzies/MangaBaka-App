import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/services/mix_series_json.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Reads the `/series/mix` recommendation endpoints.
///
/// Request plumbing lives in [ApiClient]; the mix-specific JSON shape is
/// handled by [normalizeMixSeriesJson].
class MixService {
  static const String _mixUrl = '${AppConstants.baseApiUrl}/series/mix';
  static const String _seedsUrl = '${AppConstants.baseApiUrl}/series/mix/seeds';

  final _logger = LoggingService.logger;
  final ApiClient _api;

  MixService({http.Client? client, ApiClient? api})
      : _api = api ?? ApiClient(healthContext: 'mix', client: client);

  /// Fetch mix recommendations based on seed series IDs.
  Future<MixResult> fetchMix({
    required List<int> seriesIds,
    int limit = 24,
    List<String>? contentRating,
    List<String>? notContentRating,
    bool strict = false,
    String? blendUserId,
    String? excludeUserLibrary,
  }) async {
    final url = ApiClient.uri(_mixUrl, {
      'limit': limit,
      'series': seriesIds,
      'content_rating': contentRating,
      'not_content_rating': notContentRating,
      if (strict) 'strict': 'true',
      'blend_user_id': blendUserId,
      'exclude_user_library': excludeUserLibrary,
    });

    final result = await _api.getJson(
      url,
      operation: 'fetch recommendations',
      parse: _parseMixResult,
    );

    _logger.info(
      'MixService: ${result.series.length} recommendations, '
      '${result.dna.length} DNA tags',
    );
    return result;
  }

  /// Fetch suggested additional seeds given 2+ existing seed IDs.
  ///
  /// Suggestions are an optional enhancement to the seed picker, so any
  /// failure degrades to "no suggestions" rather than propagating: the user
  /// can still search for seeds by hand, and an error banner here would
  /// interrupt a flow that is otherwise working. The failure is logged so it
  /// is still visible in diagnostics.
  Future<List<AutocompleteSeriesResult>> fetchSeedSuggestions(
    List<int> seriesIds,
  ) async {
    if (seriesIds.length < 2) return const [];

    try {
      return await _api.getJson(
        ApiClient.uri(_seedsUrl, {'series': seriesIds}),
        operation: 'fetch seed suggestions',
        parse: (json) => parseDataList(
          json,
          (item) => _mapNestedSeries(item, AutocompleteSeriesResult.fromJson),
        ),
      );
    } catch (e) {
      _logger.warning('MixService.fetchSeedSuggestions failed: $e');
      return const [];
    }
  }

  MixResult _parseMixResult(dynamic json) {
    final series = parseDataList(
      json,
      (item) => _mapNestedSeries(item, Series.fromJson),
    );

    final dnaJson = (json is Map ? json['dna'] : null);
    final dna = (dnaJson is List ? dnaJson : const [])
        .whereType<Map>()
        .map((d) {
          try {
            return MixDnaTag.fromJson(d.cast<String, dynamic>());
          } catch (e) {
            _logger.fine('MixService: skipping malformed DNA tag: $e');
            return null;
          }
        })
        .whereType<MixDnaTag>()
        .where((d) => d.name.isNotEmpty)
        .toList()
      // Heaviest traits first: the DNA strip is a summary, and the tail is
      // truncated on narrow screens.
      ..sort((a, b) => b.weight.compareTo(a.weight));

    final rawSeedCount = json is Map ? json['seed_count'] : null;
    final seedCount = rawSeedCount is num ? rawSeedCount.toInt() : 0;
    return MixResult(series: series, dna: dna, seedCount: seedCount);
  }

  /// Mix items wrap the series one level deep (`{series: {...}, ...}`).
  ///
  /// A single unparseable item yields null and is skipped by
  /// [parseDataList] — one malformed recommendation should not empty the
  /// whole rail.
  T? _mapNestedSeries<T>(
    Map<String, dynamic> item,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final seriesMap = item['series'];
    if (seriesMap is! Map) return null;
    try {
      return fromJson(normalizeMixSeriesJson(seriesMap.cast<String, dynamic>()));
    } catch (e) {
      _logger.warning('MixService: failed to parse series item: $e');
      return null;
    }
  }

  void dispose() => _api.close();
}
