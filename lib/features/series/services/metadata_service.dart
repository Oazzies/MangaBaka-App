import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/series/services/metadata_cache.dart';

class MetadataService {
  static final _logger = LoggingService.logger;

  final MetadataCache _cache;
  final ApiClient _api;

  MetadataService({http.Client? client, ApiClient? api, MetadataCache? cache})
    : _cache = cache ?? MetadataCache(),
      _api = api ?? ApiClient(healthContext: 'metadata', client: client);

  List<Map<String, dynamic>> _genresList = const [];
  List<Map<String, dynamic>> _tagsList = const [];

  Map<String, String> _genreMap = const {};
  Map<String, Map<String, dynamic>> _tagMap = const {};

  /// Replaces a per-chip linear scan over thousands of tags that stalled the first frame by ~1s.
  Map<String, Map<String, dynamic>> _tagLowerMap = const {};

  Map<int, String> _tagNameById = const {};

  bool _isInitialized = false;

  List<Map<String, dynamic>> get genres => _genresList;
  List<Map<String, dynamic>> get tags => _tagsList;
  bool get isInitialized => _isInitialized;

  /// Returns once the cache is loaded: awaiting the refresh would delay the first frame for no visible gain.
  Future<void> init() async {
    if (_isInitialized) return;
    _logger.info('Initializing MetadataService...');

    await Future.wait([_loadCachedGenres(), _loadCachedTags()]);
    _isInitialized = true;
    _logger.info('MetadataService initialized (cached)');

    unawaitedRefresh();
  }

  /// Safe unawaited: [fetchGenres] and [fetchTags] catch and log their own failures.
  void unawaitedRefresh() {
    Future.wait([
      fetchGenres(),
      fetchTags(),
    ]).then((_) => _logger.info('MetadataService fresh data fetch complete'));
  }

  Future<void> _loadCachedGenres() async {
    final cached = await _cache.read(MetadataCache.genresKey);
    if (cached == null) return;
    _applyGenres(cached);
    _logger.fine('Loaded ${cached.length} genres from cache');
  }

  Future<void> _loadCachedTags() async {
    final cached = await _cache.read(MetadataCache.tagsKey);
    if (cached == null) return;
    _applyTags(cached);
    _logger.fine('Loaded ${cached.length} tags from cache');
  }

  Future<void> fetchGenres() => _refresh(
    endpoint: '/genres',
    operation: 'fetch genres',
    cacheKey: MetadataCache.genresKey,
    current: () => _genresList,
    apply: _applyGenres,
  );

  Future<void> fetchTags() => _refresh(
    endpoint: '/tags',
    operation: 'fetch tags',
    cacheKey: MetadataCache.tagsKey,
    current: () => _tagsList,
    apply: _applyTags,
  );

  /// Failures are swallowed on purpose: the cached vocabulary stays and the user cannot act on them.
  /// Compares full encodings (lengths missed renames) to skip a SharedPreferences write per launch.
  Future<void> _refresh({
    required String endpoint,
    required String operation,
    required String cacheKey,
    required List<Map<String, dynamic>> Function() current,
    required void Function(List<Map<String, dynamic>> items) apply,
  }) async {
    try {
      final items = await _api.getJson(
        ApiClient.uri('${AppConstants.baseApiUrl}$endpoint'),
        operation: operation,
        parse: dataList,
      );
      if (items.isEmpty) return;

      final encoded = jsonEncode(items);
      if (encoded == jsonEncode(current())) return;

      apply(items);
      await _cache.write(cacheKey, encoded);
      _logger.info('Updated and cached ${items.length} entries from $endpoint');
    } catch (e) {
      _logger.warning('Metadata refresh failed for $endpoint: $e');
    }
  }

  void _applyGenres(List<Map<String, dynamic>> items) {
    _genresList = items;
    _genreMap = {
      for (final item in items)
        if (item['value'] != null)
          item['value'].toString(): item['label']?.toString() ?? '',
    };
  }

  void _applyTags(List<Map<String, dynamic>> items) {
    _tagsList = items;
    _tagMap = {
      for (final item in items)
        if (item['name'] != null) item['name'].toString(): item,
    };
    _tagLowerMap = {
      for (final entry in _tagMap.entries) entry.key.toLowerCase(): entry.value,
    };
    _tagNameById = {
      for (final item in items)
        if (int.tryParse(item['id']?.toString() ?? '') case final int id)
          id: item['name']?.toString() ?? '',
    };
  }

  Map<String, dynamic>? _lookupTag(String tagName) =>
      _tagMap[tagName] ?? _tagLowerMap[tagName.toLowerCase()];

  String getGenreLabel(String value) {
    final label = _genreMap[value];
    if (label != null && label.isNotEmpty) return label;
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  String? getTagId(String tagName) => _lookupTag(tagName)?['id']?.toString();

  String? getTagPath(String tagName) =>
      _lookupTag(tagName)?['name_path']?.toString();

  String getTagName(int id) => _tagNameById[id] ?? 'Tag $id';

  void dispose() => _api.close();
}
