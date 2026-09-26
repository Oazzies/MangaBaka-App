import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';

List<int> _varint(int v) {
  final out = <int>[];
  while (v > 0x7f) {
    out.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.add(v);
  return out;
}

List<int> _lengthDelimited(int field, List<int> payload) => [
  ..._varint(field << 3 | 2),
  ..._varint(payload.length),
  ...payload,
];

/// A BackupManga with a source (varint), url and title, like Mihon writes.
List<int> _manga(String title) => [
  ..._varint(1 << 3), ..._varint(2499283573021220255 & 0xffffff),
  ..._lengthDelimited(2, utf8.encode('/manga/x')),
  ..._lengthDelimited(3, utf8.encode(title)),
];

Uint8List _backup(List<String> titles) => Uint8List.fromList([
  for (final t in titles) ..._lengthDelimited(1, _manga(t)),
  // A field a reader has never heard of, which must be skipped.
  ..._lengthDelimited(101, utf8.encode('categories')),
]);

void main() {
  group('ImportFileReader', () {
    test('plain text passes through', () {
      expect(
        ImportFileReader.readText(Uint8List.fromList(utf8.encode('A\nB'))),
        'A\nB',
      );
    });

    test('a gzipped MyAnimeList export is unwrapped', () {
      const xml = '<myanimelist><manga><manga_title>A</manga_title></manga></myanimelist>';
      final text = ImportFileReader.readText(
        Uint8List.fromList(gzip.encode(utf8.encode(xml))),
      );
      expect(text, xml);
      expect(ImportParser.parse(text).map((e) => e.title), ['A']);
    });

    test('a Mihon backup yields its titles, gzipped or not', () {
      final backup = _backup(['Frieren', 'Berserk 日本']);
      expect(ImportFileReader.readText(backup), 'Frieren\nBerserk 日本');
      expect(
        ImportFileReader.readText(
          Uint8List.fromList(gzip.encode(backup)),
        ),
        'Frieren\nBerserk 日本',
      );
    });

    test('unreadable binary is refused rather than imported as junk', () {
      expect(
        () => ImportFileReader.readText(
          Uint8List.fromList([0xff, 0xfe, 0x00, 0x01, 0x02]),
        ),
        throwsA(isA<ImportSourceException>()),
      );
    });
  });

  group('AniListImporter', () {
    const body = '''
{"data": {"MediaListCollection": {"lists": [
  {"entries": [
    {"status": "CURRENT", "media": {"title": {"romaji": "Sousou no Frieren", "english": "Frieren"}}},
    {"status": "PLANNING", "media": {"title": {"romaji": null, "english": "Berserk"}}}
  ]},
  {"entries": [
    {"status": "PAUSED", "media": {"title": {"romaji": "Monster", "english": null}}}
  ]}
]}}}''';

    test('turns entries into importer JSON that the parser maps', () {
      final entries = ImportParser.parse(AniListImporter.entriesJson(body));
      expect(entries, const [
        ImportEntry('Sousou no Frieren', state: 'reading'),
        ImportEntry('Berserk', state: 'plan_to_read'),
        ImportEntry('Monster', state: 'paused'),
      ]);
    });

    test('an unknown user is reported as such', () {
      expect(
        () => AniListImporter.entriesJson('{"data": null, "errors": []}'),
        throwsA(
          isA<ImportSourceException>().having(
            (e) => e.key,
            'key',
            'import_user_not_found',
          ),
        ),
      );
    });

    test('fetch posts the username and returns the entries', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(body, 200);
      });
      final json = await AniListImporter(client: client).fetch('  someone ');
      expect((sent['variables'] as Map)['user'], 'someone');
      expect(ImportParser.parse(json), hasLength(3));
    });

    test('a missing user and a dead server are told apart', () async {
      Future<String> key(int status) async {
        final importer = AniListImporter(
          client: MockClient((_) async => http.Response('{}', status)),
        );
        try {
          await importer.fetch('x');
        } on ImportSourceException catch (e) {
          return e.key;
        }
        return '';
      }

      expect(await key(404), 'import_user_not_found');
      expect(await key(500), 'import_source_unreachable');
    });
  });

  group('KitsuImporter', () {
    const usersBody = '{"data":[{"id":"7","type":"users"}]}';
    const entriesBody = '''
{"data":[
  {"id":"1","type":"libraryEntries","attributes":{"status":"current"},
   "relationships":{"manga":{"data":{"type":"manga","id":"10"}}}},
  {"id":"2","type":"libraryEntries","attributes":{"status":"planned"},
   "relationships":{"manga":{"data":{"type":"manga","id":"11"}}}}
],"included":[
  {"id":"10","type":"manga","attributes":{"canonicalTitle":"Frieren","titles":{"en":"Frieren"}}},
  {"id":"11","type":"manga","attributes":{"canonicalTitle":"Berserk","titles":{"en":"Berserk"}}}
],"links":{}}''';

    test('resolves the username then maps entries into importer JSON',
        () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/users')) {
          return http.Response(usersBody, 200);
        }
        return http.Response(entriesBody, 200);
      });

      final json = await KitsuImporter(client: client).fetch('someone');

      expect(ImportParser.parse(json), const [
        ImportEntry('Frieren', state: 'reading'),
        ImportEntry('Berserk', state: 'plan_to_read'),
      ]);
    });

    test('an empty username is rejected before any request', () async {
      final importer = KitsuImporter(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(
        () => importer.fetch('   '),
        throwsA(
          isA<ImportSourceException>().having(
            (e) => e.key,
            'key',
            'import_user_empty',
          ),
        ),
      );
    });

    test('an unknown user is reported as such', () async {
      final importer = KitsuImporter(
        client: MockClient((_) async => http.Response('{"data":[]}', 200)),
      );
      expect(
        () => importer.fetch('ghost'),
        throwsA(
          isA<ImportSourceException>().having(
            (e) => e.key,
            'key',
            'import_user_not_found',
          ),
        ),
      );
    });

    test('a dead server is reported as unreachable', () async {
      final importer = KitsuImporter(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(
        () => importer.fetch('someone'),
        throwsA(
          isA<ImportSourceException>().having(
            (e) => e.key,
            'key',
            'import_source_unreachable',
          ),
        ),
      );
    });
  });
}
