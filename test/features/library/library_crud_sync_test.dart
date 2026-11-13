import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'library_crud_test_harness.dart';

void main() {
  final h = LibraryCrudTestHarness();

  setUp(h.setUp);
  tearDown(h.tearDown);

  group('library sync', () {
    test(
      'a rejected page marks the library incomplete and keeps the watermark',
      () async {
        await h.withServer(
          (_) async => http.Response('bad request', 400),
          () => h.service.syncLibrary(),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(await h.service.isLibraryIncomplete(), isTrue);
        expect(prefs.getString(AppConstants.lastSyncKey), isNull);
        expect(h.service.syncStatus.value.isSyncing, isFalse);
      },
    );

    group('change feed', () {
      Map<String, dynamic> entryItem(int seriesId, {int? rating}) => {
        'type': 'entry',
        'action': 'upsert',
        'revision': 1,
        'current': {
          'id': 1000 + seriesId,
          'series_id': seriesId,
          'state': 'reading',
          'rating': rating,
          'progress_chapter': 3,
        },
      };

      http.Response feed(
        List<Map<String, dynamic>> items, {
        String cursor = 'c1',
        bool more = false,
      }) => http.Response(
        jsonEncode({
          'data': items,
          'pagination': {'limit': 1000, 'cursor': cursor, 'more': more},
        }),
        200,
      );

      http.Response batch(Iterable<int> ids) => http.Response(
        jsonEncode({
          'data': [
            for (final id in ids) {'id': id, 'title': 'Series $id'},
          ],
        }),
        200,
      );

      Future<http.Response> server(http.Request r) async =>
          r.url.path.endsWith('/series/batch')
          ? batch(r.url.queryParametersAll['id']!.map(int.parse))
          : feed([entryItem(42, rating: 9)]);

      test(
        'the first sync scans from the start and stores the cursor',
        () async {
          await h.withServer(server, () => h.service.syncLibrary());
          final changes = h.requests.firstWhere(
            (r) => r.url.path.endsWith('/changes'),
          );
          expect(changes.url.queryParameters.containsKey('cursor'), isFalse);
          expect(changes.url.queryParameters['limit'], '1000');
          expect((await h.entryFor('42'))!.rating, 9);
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString(AppConstants.libraryCursorKey), 'c1');
          expect(await h.service.isLibraryIncomplete(), isFalse);
        },
      );

      test('a later sync sends the stored cursor', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'saved',
          librarySeriesDataKey: librarySeriesDataVersion,
        });
        await h.withServer(
          (_) async => feed([], cursor: 'next'),
          () => h.service.syncLibrary(),
        );
        expect(h.requests.single.url.queryParameters['cursor'], 'saved');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.libraryCursorKey), 'next');
      });

      test(
        'series are fetched from v1, which carries the canonical titles',
        () async {
          await h.withServer(server, () => h.service.syncLibrary());
          final batchRequest = h.requests.firstWhere(
            (r) => r.url.path.endsWith('/series/batch'),
          );
          expect(batchRequest.url.path, startsWith('/v1/'));
        },
      );

      test(
        'series stored by an older data generation are re-fetched once',
        () async {
          await h.seedEntry('42');
          await (h.db.update(
            h.db.seriesTable,
          )..where((t) => t.id.equals('42'))).write(
            const SeriesTableCompanion(title: Value('Guessed title')),
          );
          SharedPreferences.setMockInitialValues({
            AppConstants.libraryCursorKey: 'saved',
          });

          await h.withServer(server, () => h.service.syncLibrary());

          final changes = h.requests.firstWhere(
            (r) => r.url.path.endsWith('/changes'),
          );
          expect(changes.url.queryParameters.containsKey('cursor'), isFalse);
          final row = await (h.db.select(
            h.db.seriesTable,
          )..where((t) => t.id.equals('42'))).getSingle();
          expect(row.title, 'Series 42');
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getInt(librarySeriesDataKey),
            librarySeriesDataVersion,
          );

          h.requests.clear();
          await h.withServer(
            (_) async => feed([], cursor: 'c2'),
            () => h.service.syncLibrary(),
          );
          expect(h.requests.single.url.queryParameters['cursor'], 'c1');
        },
      );

      test('a delete removes the entry', () async {
        await h.seedEntry('42');
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'saved',
        });
        await h.withServer(
          (_) async => feed([
            {
              'type': 'entry',
              'action': 'delete',
              'current': {'series_id': 42},
            },
          ]),
          () => h.service.syncLibrary(),
        );
        expect(await h.entryFor('42'), isNull);
      });

      test('a rejected cursor rescans from the start', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'stale',
        });
        await h.withServer(
          (r) async => r.url.path.endsWith('/series/batch')
              ? batch([42])
              : r.url.queryParameters['cursor'] == 'stale'
              ? http.Response('bad cursor', 400)
              : feed([entryItem(42)], cursor: 'fresh'),
          () => h.service.syncLibrary(),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.libraryCursorKey), 'fresh');
        expect(await h.entryFor('42'), isNotNull);
      });

      test(
        'a full scan drops local entries the server no longer lists',
        () async {
          await h.seedEntry('7');
          await h.withServer(server, () => h.service.syncLibrary(deep: true));
          expect(await h.entryFor('7'), isNull);
          expect(await h.entryFor('42'), isNotNull);
        },
      );
    });

    test('a page fetch recovers from a revoked token', () async {
      await h.withServer(
        (r) async => h.bearerIsNew(r)
            ? http.Response(jsonEncode({'data': []}), 200)
            : http.Response('', 401),
        () => h.service.syncLibrary(),
      );

      expect(h.refreshCalls, 1);
      expect(h.service.syncStatus.value.error, isNull);
    });
  });
}
