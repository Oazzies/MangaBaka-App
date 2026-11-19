import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/logging/logging_service.dart';

export 'package:mangabaka_app/features/library/import/kitsu_importer.dart';

class ImportSourceException implements Exception {
  final String key;

  const ImportSourceException(this.key);

  @override
  String toString() => 'ImportSourceException($key)';
}

/// MyAnimeList exports are often .xml.gz and Mihon backups gzipped protobuf; both unwrap here.
abstract final class ImportFileReader {
  /// Also caps gzip expansion: a small .gz can inflate a thousand-fold and exhaust memory.
  static const int maxBytes = 50 * 1024 * 1024;

  static String readText(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const ImportSourceException('import_file_failed');
    }
    var data = bytes;
    if (data.length > 2 && data[0] == 0x1f && data[1] == 0x8b) {
      try {
        data = _gunzipBounded(data);
      } catch (e, st) {
        LoggingService.logger.warning('Failed to gunzip import file', e, st);
        throw const ImportSourceException('import_file_failed');
      }
    }

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

Uint8List _gunzipBounded(Uint8List data) {
  final out = BytesBuilder(copy: false);
  final sink = _LimitedSink(out, ImportFileReader.maxBytes);
  final conversion = gzip.decoder.startChunkedConversion(sink);
  conversion.add(data);
  conversion.close();
  return out.takeBytes();
}

class _LimitedSink implements Sink<List<int>> {
  final BytesBuilder _out;
  final int _limit;

  _LimitedSink(this._out, this._limit);

  @override
  void add(List<int> chunk) {
    _out.add(chunk);
    if (_out.length > _limit) {
      throw const FormatException('decompressed file is too large');
    }
  }

  @override
  void close() {}
}

/// Hand-parsed: two field numbers do not justify a protobuf dependency.
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

  final Uint8List? bytes;

  const _Field(this.number, this.bytes);
}

/// AniList needs no key for public lists; the result is importer JSON, reviewed like any source.
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
    } catch (e, st) {
      LoggingService.logger.warning('AniList import request failed', e, st);
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

  static String entriesJson(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
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
