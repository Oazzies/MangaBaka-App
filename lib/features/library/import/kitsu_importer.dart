import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';

/// Fetches a public Kitsu manga library by username, via Kitsu's own public
/// JSON:API (`kitsu.io/api/edge`) — no key needed, unlike a MyAnimeList list,
/// which has no public read API of its own to fetch this way.
class KitsuImporter {
  static final Uri _usersEndpoint = Uri.parse(
    'https://kitsu.io/api/edge/users',
  );
  static final Uri _entriesEndpoint = Uri.parse(
    'https://kitsu.io/api/edge/library-entries',
  );

  /// Entries read before giving up on a very large public library. The
  /// parser trims to `ImportParser.maxTitles` anyway; this just bounds how
  /// many pages a single import fetches.
  static const int _maxEntries = 300;
  static const int _maxPages = 10;

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.api+json',
  };

  final http.Client _client;

  KitsuImporter({http.Client? client}) : _client = client ?? http.Client();

  Future<String> fetch(String username) async {
    final name = username.trim();
    if (name.isEmpty) throw const ImportSourceException('import_user_empty');

    final userId = await _resolveUserId(name);
    if (userId == null) {
      throw const ImportSourceException('import_user_not_found');
    }

    final entries = <Map<String, String>>[];
    Uri? next = _entriesEndpoint.replace(
      queryParameters: {
        'filter[userId]': userId,
        'filter[kind]': 'manga',
        'include': 'manga',
        'fields[manga]': 'canonicalTitle,titles',
        'fields[libraryEntries]': 'status',
        'page[limit]': '100',
      },
    );

    // Bounded on pages as well as entries: pages whose rows all lack a title
    // add nothing to [entries], so a feed that keeps linking to a "next" page
    // would otherwise loop forever.
    var pages = 0;
    while (next != null &&
        entries.length < _maxEntries &&
        pages++ < _maxPages) {
      final Map<String, dynamic> page = await _getJson(next);

      final included = page['included'];
      final mangaById = <String, dynamic>{};
      if (included is List) {
        for (final item in included) {
          if (item is Map && item['type'] == 'manga' && item['id'] != null) {
            mangaById[item['id'].toString()] = item['attributes'];
          }
        }
      }

      final data = page['data'];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final attrs = item['attributes'];
          final status = attrs is Map ? attrs['status']?.toString() : null;
          final relationships = item['relationships'];
          final mangaRel = relationships is Map ? relationships['manga'] : null;
          final mangaData = mangaRel is Map ? mangaRel['data'] : null;
          final mangaId = mangaData is Map ? mangaData['id']?.toString() : null;
          final title = _titleOf(mangaId != null ? mangaById[mangaId] : null);
          if (title == null || title.trim().isEmpty) continue;
          entries.add({'title': title, 'status': status ?? ''});
        }
      }

      final links = page['links'];
      final nextUrl = links is Map ? links['next']?.toString() : null;
      final parsed = nextUrl != null ? Uri.tryParse(nextUrl) : null;
      // The link comes from the response: only follow it back to Kitsu.
      next =
          parsed != null &&
              parsed.scheme == 'https' &&
              parsed.host == _entriesEndpoint.host
          ? parsed
          : null;
    }

    return jsonEncode(entries);
  }

  Future<String?> _resolveUserId(String username) async {
    final uri = _usersEndpoint.replace(
      queryParameters: {'filter[slug]': username},
    );
    final page = await _getJson(uri);
    final data = page['data'];
    if (data is! List || data.isEmpty) return null;
    final first = data.first;
    return first is Map ? first['id']?.toString() : null;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 20));
    } catch (e, st) {
      LoggingService.logger.warning('Kitsu import request failed', e, st);
      throw const ImportSourceException('import_source_unreachable');
    }
    if (response.statusCode != 200) {
      throw const ImportSourceException('import_source_unreachable');
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Handled below: not JSON is as unusable as the wrong shape.
    }
    throw const ImportSourceException('import_source_unreachable');
  }

  /// Kitsu's own computed display title, falling back to an English one.
  static String? _titleOf(Object? mangaAttrs) {
    if (mangaAttrs is! Map) return null;
    final canonical = mangaAttrs['canonicalTitle'];
    if (canonical is String && canonical.trim().isNotEmpty) return canonical;
    final titles = mangaAttrs['titles'];
    if (titles is Map) {
      final t = titles['en'] ?? titles['en_jp'] ?? titles['en_us'];
      if (t is String && t.trim().isNotEmpty) return t;
    }
    return null;
  }

  void dispose() => _client.close();
}
