import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/services/mix_series_json.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

class MixService {
  static const String _mixUrl = '${AppConstants.baseApiUrl}/series/mix';
  static const String _seedsUrl = '${AppConstants.baseApiUrl}/series/mix/seeds';

  final _logger = LoggingService.logger;
  final ApiClient _api;

  MixService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'mix', client: client);

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

  /// Failures degrade to no suggestions: seeds can still be searched for by hand.
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
    final dna =
        (dnaJson is List ? dnaJson : const [])
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
          // Heaviest first: the DNA strip truncates its tail on narrow screens.
          ..sort((a, b) => b.weight.compareTo(a.weight));

    final rawSeedCount = json is Map ? json['seed_count'] : null;
    final seedCount = rawSeedCount is num ? rawSeedCount.toInt() : 0;
    return MixResult(series: series, dna: dna, seedCount: seedCount);
  }

  /// Mix items nest the series (`{series: {...}}`); a malformed one yields null and is skipped.
  T? _mapNestedSeries<T>(
    Map<String, dynamic> item,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final seriesMap = item['series'];
    if (seriesMap is! Map) return null;
    try {
      return fromJson(
        normalizeMixSeriesJson(seriesMap.cast<String, dynamic>()),
      );
    } catch (e) {
      _logger.warning('MixService: failed to parse series item: $e');
      return null;
    }
  }

  void dispose() => _api.close();
}
