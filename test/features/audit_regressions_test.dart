import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

void main() {
  group('Series.fromJson tolerates malformed payloads', () {
    test('non-string list elements do not survive to throw later', () {
      final s = Series.fromJson({
        'id': 1,
        'title': 'T',
        'genres': ['action', null, 3],
        'tags': 'not a list',
        'authors': [null, 'A'],
        'publishers': ['Plain', null, {'name': 'Pub'}, 5],
      });
      // Encoding is what the database layer does; a lazy cast would throw here.
      expect(() => jsonEncode(s.genres), returnsNormally);
      expect(s.genres, ['action']);
      expect(s.tags, isEmpty);
      expect(s.authors, ['A']);
      expect(s.publishers, containsAll(['Plain', 'Pub']));
    });

    test('numeric title and state are stringified, not thrown on', () {
      final s = Series.fromJson({'id': '1', 'title': 1999, 'state': 7});
      expect(s.title, '1999');
      expect(s.state, '7');
    });

    test('similar/recommendation shapes skip bad children', () {
      final s = Series.fromSimilarJson({
        'id': '1',
        'title': 'T',
        'genres_v2': [
          {'name': 'Drama'},
          'oops',
          null,
        ],
        'tags_v2': 'bad',
      });
      expect(s.genres, contains('Drama'));
      expect(
        () => Series.fromRecommendationJson({
          'id': '1',
          'title': 'T',
          'reason': {'top_tags': 'nope'},
        }),
        returnsNormally,
      );
    });
  });

  test('JsonUtils.normalizedRating ignores non-finite values', () {
    expect(JsonUtils.normalizedRating({'rating_normalized': 'NaN'}), isNull);
    expect(JsonUtils.normalizedRating({'rating_normalized': 'Infinity'}), isNull);
    expect(JsonUtils.normalizedRating({'rating_normalized': '7.5'}), 7.5);
  });

  test('LibraryEntry without an id is rejected', () {
    expect(
      () => LibraryEntry.fromJson({
        'state': 'reading',
        'series': {'id': '1', 'title': 'T'},
      }),
      throwsFormatException,
    );
    expect(
      () => LibraryEntry.fromJson({
        'id': '9',
        'state': 'reading',
        'series': {'title': 'T'},
      }),
      throwsFormatException,
    );
  });

  test('StringListSetting keeps its own copy of the list', () {
    final setting = StringListSetting('k', const ['a']);
    final input = ['a', 'b'];
    expect(setting.set(input), isTrue);
    input.add('c');
    expect(setting.value, ['a', 'b']);
    expect(setting.set(['a', 'b']), isFalse);
  });

  group('CSV import', () {
    test('a quoted multi-line note stays inside its row', () {
      const csv = 'title,state,note\n'
          '"One, Piece",reading,"line one\nline two"\n'
          'Berserk,completed,\n';
      final entries = ImportParser.parse(csv, format: ImportFormat.csv);
      expect(entries.map((e) => e.title), ['One, Piece', 'Berserk']);
      expect(entries.first.state, 'reading');
    });

    test('CRLF files still split into rows', () {
      final entries = ImportParser.parse(
        'title\r\nA\r\nB\r\n',
        format: ImportFormat.csv,
      );
      expect(entries.map((e) => e.title), ['A', 'B']);
    });
  });

  group('ImportFileReader', () {
    test('reads gzipped text', () {
      final bytes = Uint8List.fromList(gzip.encode(utf8.encode('A\nB')));
      expect(ImportFileReader.readText(bytes), 'A\nB');
    });

    test('rejects a gzip that inflates past the limit', () {
      final bomb = Uint8List.fromList(
        gzip.encode(Uint8List(ImportFileReader.maxBytes + 1024)),
      );
      expect(
        () => ImportFileReader.readText(bomb),
        throwsA(isA<ImportSourceException>()),
      );
    });
  });

  test('AppRelease.fromJson survives odd field types', () {
    final r = AppRelease.fromJson({
      'tag_name': 5,
      'name': null,
      'draft': 'yes',
      'assets': [
        {'name': 'a.apk', 'size': 12.0, 'browser_download_url': null},
      ],
    });
    expect(r.tagName, '5');
    expect(r.draft, isFalse);
    expect(r.assets.single.size, 12);
  });
}
