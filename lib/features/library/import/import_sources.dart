import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Something went wrong reading an import source. [key] is a localization key.
class ImportSourceException implements Exception {
  final String key;

  const ImportSourceException(this.key);

  @override
  String toString() => 'ImportSourceException($key)';
}

/// Turns the bytes of an import file into the text the parser reads.
///
/// Most sources are already text. Two are not: a MyAnimeList export is usually
/// downloaded gzipped (`.xml.gz`), and a Mihon backup (`.tachibk`, or
/// `.proto.gz`) is a gzipped protobuf. Both are unwrapped here, so the text box
/// always shows what will be imported — for a Mihon backup, its titles.
abstract final class ImportFileReader {
  static String readText(Uint8List bytes) {
    var data = bytes;
    if (data.length > 2 && data[0] == 0x1f && data[1] == 0x8b) {
      try {
        data = Uint8List.fromList(gzip.decode(data));
      } catch (_) {
        throw const ImportSourceException('import_file_failed');
      }
    }

    // Text if it decodes strictly as UTF-8 and holds no control bytes;
    // otherwise it can only be a protobuf backup.
    try {
      final text = utf8.decode(data);
      if (!text.codeUnits.any((c) => c == 0)) return text;
    } on FormatException {
      // Not text; fall through.
    }

    final titles = MihonBackup.titles(data);
    if (titles.isEmpty) throw const ImportSourceException('import_file_failed');
    return titles.join('\n');
  }
}

/// Reads the manga titles out of a Mihon (or Tachiyomi) backup.
///
/// A backup is a protobuf `Backup` whose repeated field 1 is a `BackupManga`,
/// and a `BackupManga`'s field 3 is its title. Only that path is read, by hand:
/// it is two field numbers, not worth a protobuf dependency, and unknown fields
/// (of which a backup has many, and more with every release) are skipped by
/// their wire type.
abstract final class MihonBackup {
  static const int _backupMangaField = 1;
  static const int _titleField = 3;

  static List<String> titles(Uint8List data) {
    final titles = <String>[];
    try {
      for (final field in _fields(data)) {
        if (field.number != _backupMangaField || field.bytes == null) continue;
        for (final inner in _fields(field.bytes!)) {
          if (inner.number == _titleField && inner.bytes != null) {
            final title = utf8.decode(inner.bytes!, allowMalformed: true);
            if (title.trim().isNotEmpty) titles.add(title);
          }
        }
      }
    } on FormatException {
      // Truncated or not protobuf at all: whatever was read stands.
    }
    return titles;
  }

  static Iterable<_Field> _fields(Uint8List data) sync* {
    var i = 0;

    int varint() {
      var result = 0;
      var shift = 0;
      while (true) {
        if (i >= data.length || shift > 63) {
          throw const FormatException('bad varint');
        }
        final b = data[i++];
        result |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) return result;
        shift += 7;
      }
    }

    while (i < data.length) {
      final tag = varint();
      final number = tag >> 3;
      switch (tag & 7) {
        case 0:
          varint();
          yield _Field(number, null);
        case 1:
          i += 8;
          yield _Field(number, null);
        case 2:
          final length = varint();
          if (length < 0 || i + length > data.length) {
            throw const FormatException('bad length');
          }
          yield _Field(number, Uint8List.sublistView(data, i, i + length));
          i += length;
        case 5:
          i += 4;
          yield _Field(number, null);
        default:
          throw const FormatException('unsupported wire type');
      }
    }
  }
}

class _Field {
  final int number;

  /// The payload of a length-delimited field; null for the fixed-size kinds.
  final Uint8List? bytes;

  const _Field(this.number, this.bytes);
}

/// Fetches a public AniList manga list by username.
///
/// AniList's API needs no key for public lists. The result is JSON text in the
/// shape the importer already reads (`[{"title": …, "status": …}]`), so it goes
/// through the same review as any other source.
class AniListImporter {
  static final Uri _endpoint = Uri.parse('https://graphql.anilist.co');

  static const String _query = r'''
query ($user: String) {
  MediaListCollection(userName: $user, type: MANGA) {
    lists { entries { status media { title { romaji english } } } }
  }
}''';

  final http.Client _client;

  AniListImporter({http.Client? client}) : _client = client ?? http.Client();

  Future<String> fetch(String username) async {
    final name = username.trim();
    if (name.isEmpty) throw const ImportSourceException('import_user_empty');

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': _query,
              'variables': {'user': name},
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ImportSourceException('import_source_unreachable');
    }

    if (response.statusCode == 404) {
      throw const ImportSourceException('import_user_not_found');
    }
    if (response.statusCode != 200) {
      throw const ImportSourceException('import_source_unreachable');
    }
    return entriesJson(response.body);
  }

  /// Converts an AniList response body into importer JSON.
  static String entriesJson(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const ImportSourceException('import_source_unreachable');
    }
    final data = decoded is Map ? decoded['data'] : null;
    final collection = data is Map ? data['MediaListCollection'] : null;
    final lists = collection is Map ? collection['lists'] : null;
    if (lists is! List) {
      throw const ImportSourceException('import_user_not_found');
    }

    final out = <Map<String, String>>[];
    for (final list in lists) {
      final entries = list is Map ? list['entries'] : null;
      if (entries is! List) continue;
      for (final entry in entries) {
        if (entry is! Map) continue;
        final titles = entry['media'] is Map ? entry['media']['title'] : null;
        if (titles is! Map) continue;
        final title = (titles['romaji'] ?? titles['english'])?.toString();
        if (title == null || title.trim().isEmpty) continue;
        out.add({'title': title, 'status': entry['status']?.toString() ?? ''});
      }
    }
    return jsonEncode(out);
  }

  void dispose() => _client.close();
}

/// Fetches a public Kitsu manga library by username, via Kitsu's own public
/// JSON:API (`kitsu.io/api/edge`) — no key needed, unlike a MyAnimeList list,
/// which has no public read API of its own to fetch this way.
class KitsuImporter {
  static final Uri _usersEndpoint = Uri.parse('https://kitsu.io/api/edge/users');
  static final Uri _entriesEndpoint = Uri.parse(
    'https://kitsu.io/api/edge/library-entries',
  );

  /// Entries read before giving up on a very large public library. The
  /// parser trims to `ImportParser.maxTitles` anyway; this just bounds how
  /// many pages a single import fetches.
  static const int _maxEntries = 300;

  static const Map<String, String> _headers = {
    'Accept': 'application/vnd.api+json',
  };

  final http.Client _client;

  KitsuImporter({http.Client? client}) : _client = client ?? http.Client();

  Future<String> fetch(String username) async {
    final name = username.trim();
    if (name.isEmpty) throw const ImportSourceException('import_user_empty');

    final userId = await _resolveUserId(name);
    if (userId == null) throw const ImportSourceException('import_user_not_found');

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

    while (next != null && entries.length < _maxEntries) {
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
      next = nextUrl != null ? Uri.parse(nextUrl) : null;
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
    } catch (_) {
      throw const ImportSourceException('import_source_unreachable');
    }
    if (response.statusCode != 200) {
      throw const ImportSourceException('import_source_unreachable');
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
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
