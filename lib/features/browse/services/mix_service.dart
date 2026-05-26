import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class MixService {
  static const String _mixUrl = '${AppConstants.baseApiUrl}/series/mix';
  static const String _seedsUrl = '${AppConstants.baseApiUrl}/series/mix/seeds';

  final _logger = LoggingService.logger;
  final http.Client _client;

  MixService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch mix recommendations based on seed series IDs.
  Future<MixResult> fetchMix({
    required List<int> seriesIds,
    int limit = 24,
    List<String>? contentRating,
    bool strict = false,
    String? blendUserId,
    String? excludeUserLibrary,
  }) async {
    final params = <String, dynamic>{
      'limit': limit.toString(),
    };

    for (final id in seriesIds) {
      params['series'] ??= <String>[];
      (params['series'] as List<String>).add(id.toString());
    }

    if (contentRating != null && contentRating.isNotEmpty) {
      params['content_rating'] = contentRating;
    }

    if (strict) params['strict'] = 'true';
    if (blendUserId != null && blendUserId.isNotEmpty) {
      params['blend_user_id'] = blendUserId;
    }
    if (excludeUserLibrary != null && excludeUserLibrary.isNotEmpty) {
      params['exclude_user_library'] = excludeUserLibrary;
    }

    final uri = Uri.parse(_mixUrl).replace(
      queryParameters: params.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, value.toString());
      }),
    );

    _logger.info('MixService.fetchMix URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('MixService.fetchMix status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = (json['data'] as List?) ?? [];
        final dnaList = (json['dna'] as List?) ?? [];
        final seedCount = (json['seed_count'] as int?) ?? 0;

        final series = dataList
            .map((item) => _seriesFromMixItem(item as Map<String, dynamic>))
            .whereType<Series>()
            .toList();

        final dna = dnaList
            .map((d) => MixDnaTag.fromJson(d as Map<String, dynamic>))
            .where((d) => d.name.isNotEmpty)
            .toList();

        // Sort DNA by weight descending for display
        dna.sort((a, b) => b.weight.compareTo(a.weight));

        _logger.info('MixService: ${series.length} recommendations, ${dna.length} DNA tags');
        return MixResult(series: series, dna: dna, seedCount: seedCount);
      } else {
        _logger.warning('MixService.fetchMix failed: ${response.statusCode}');
        throw Exception('Mix request failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      _logger.severe('MixService network error: $e');
      throw Exception('Network error. Please check your connection.');
    } on TimeoutException {
      _logger.severe('MixService request timed out');
      throw Exception('Request timed out. Please try again.');
    }
  }

  /// Fetch suggested additional seeds given 2+ existing seed IDs.
  Future<List<AutocompleteSeriesResult>> fetchSeedSuggestions(
    List<int> seriesIds,
  ) async {
    if (seriesIds.length < 2) return [];

    final queryParams = seriesIds.map((id) => 'series=${Uri.encodeComponent(id.toString())}').join('&');
    final uri = Uri.parse('$_seedsUrl?$queryParams');

    _logger.info('MixService.fetchSeedSuggestions URI: $uri');

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('MixService.fetchSeedSuggestions status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = (json['data'] as List?) ?? [];

        return dataList
            .map((item) {
              final m = item as Map<String, dynamic>;
              final seriesMap = m['series'] as Map<String, dynamic>?;
              if (seriesMap == null) return null;
              return AutocompleteSeriesResult.fromJson(_normalizeMixSeriesJson(seriesMap));
            })
            .whereType<AutocompleteSeriesResult>()
            .toList();
      } else {
        _logger.warning('MixService.fetchSeedSuggestions failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.warning('MixService.fetchSeedSuggestions error: $e');
      return [];
    }
  }

  /// Parses a mix data item (which has `series` nested inside) into a [Series].
  Series? _seriesFromMixItem(Map<String, dynamic> item) {
    try {
      final seriesMap = item['series'] as Map<String, dynamic>?;
      if (seriesMap == null) return null;
      return Series.fromJson(_normalizeMixSeriesJson(seriesMap));
    } catch (e) {
      _logger.warning('MixService: failed to parse series item: $e');
      return null;
    }
  }

  /// Normalizes the mix API series object to match the field names expected
  /// by [Series.fromJson]. The mix API uses `titles[]`, `genres_v2[]`, `tags_v2[]`
  /// whereas the search API uses flat `title`, `genres`, `tags`.
  Map<String, dynamic> _normalizeMixSeriesJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // --- Title normalization ---
    // Mix uses `titles` array; search uses flat `title`, `native_title`, `romanized_title`
    if (!normalized.containsKey('title') || (normalized['title'] == null)) {
      final titles = json['titles'] as List?;
      if (titles != null && titles.isNotEmpty) {
        // Prefer primary english title, then any primary, then first
        Map? primaryEn;
        Map? primary;
        Map? first;

        for (final t in titles) {
          if (t is! Map) continue;
          first ??= t;
          if (t['is_primary'] == true) {
            primary ??= t;
            final lang = t['language']?.toString() ?? '';
            if (lang == 'en') {
              primaryEn ??= t;
            }
          }
        }

        final chosen = primaryEn ?? primary ?? first;
        normalized['title'] = chosen?['title']?.toString() ?? '';

        // Native / romanized — pick jp and romanized from traits
        for (final t in titles) {
          if (t is! Map) continue;
          final lang = t['language']?.toString() ?? '';
          final traits = (t['traits'] as List?)?.cast<String>() ?? [];
          if (lang == 'ja' || lang == 'ja-ro') {
            if (traits.contains('romanized') && !normalized.containsKey('romanized_title')) {
              normalized['romanized_title'] = t['title']?.toString() ?? '';
            } else if (!traits.contains('romanized') && !normalized.containsKey('native_title')) {
              normalized['native_title'] = t['title']?.toString() ?? '';
            }
          }
        }
      }
    }

    normalized.putIfAbsent('native_title', () => '');
    normalized.putIfAbsent('romanized_title', () => '');

    // --- Genre normalization ---
    // Mix uses `genres_v2` array of objects; search uses `genres` array of strings
    if (!normalized.containsKey('genres') || normalized['genres'] == null) {
      final genresV2 = json['genres_v2'] as List?;
      if (genresV2 != null) {
        normalized['genres'] = genresV2
            .whereType<Map>()
            .where((g) => g['is_genre'] == true)
            .map((g) => g['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    }

    // --- Tag normalization ---
    if (!normalized.containsKey('tags') || normalized['tags'] == null) {
      final tagsV2 = json['tags_v2'] as List?;
      if (tagsV2 != null) {
        normalized['tags'] = tagsV2
            .whereType<Map>()
            .where((t) => t['is_genre'] != true)
            .map((t) => t['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    }

    // --- Publishers normalization ---
    // Mix uses `publishers` array of objects; search does too — already compatible.

    // --- Published year ---
    if (!normalized.containsKey('year') || normalized['year'] == null) {
      final published = json['published'] as Map?;
      if (published != null) {
        final startDate = published['start_date']?.toString() ?? '';
        if (startDate.length >= 4) {
          normalized['year'] = int.tryParse(startDate.substring(0, 4));
        }
      }
    }

    // Ensure cover is present (same structure)
    normalized.putIfAbsent('cover', () => null);

    return normalized;
  }
}
