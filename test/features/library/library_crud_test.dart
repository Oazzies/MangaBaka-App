import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_mixin.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/auth_test_helpers.dart';

/// Exercises the library write path (LibraryCrudMixin) and the sync's page
/// fetch against a fake server, with the real [ProfileAuthService] so that
/// 401 recovery is covered end to end.
void main() {
  late AppDatabase db;
  late MemoryAuthStorage storage;
  late ProfileAuthService auth;
  late LibraryService service;
  late List<http.Request> requests;
  late int refreshCalls;

  setUp(() async {
    await resetServiceLocator();
    SettingsManager.resetForTesting();
    getIt.registerSingleton<LoggingService>(LoggingService());
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());

    storage = MemoryAuthStorage();
    seedSession(storage, access: 'old');
    refreshCalls = 0;
    auth = ProfileAuthService(
      storage: storage,
      network: FakeAuthNetwork(),
      refresher: (_) async {
        refreshCalls++;
        return tokens('new', refresh: 'refresh-2');
      },
    );
    service = LibraryService(auth: auth, database: db);
    requests = [];
  });

  tearDown(() async {
    await db.close();
    SettingsManager.resetForTesting();
    await resetServiceLocator();
  });

  /// Runs [body] with every `package:http` call answered by [handler].
  Future<T> withServer<T>(
    Future<http.Response> Function(http.Request request) handler,
    Future<T> Function() body,
  ) =>
      http.runWithClient(
        body,
        () => MockClient((request) {
          requests.add(request);
          return handler(request);
        }),
      );

  /// Accepts only the refreshed token, as after a server-side revocation.
  bool bearerIsNew(http.Request r) =>
      r.headers['Authorization'] == 'Bearer new';

  Future<void> seedEntry(
    String seriesId, {
    String state = 'reading',
    String? seriesStatus,
    int? chapter,
    String? totalChapters,
    int? volume,
    String? finalVolume,
  }) async {
    await db.into(db.seriesTable).insert(
          SeriesTableCompanion.insert(
            id: seriesId,
            title: 'Series $seriesId',
            coverUrl: 'url',
            description: 'desc',
            status: Value(seriesStatus),
            totalChapters: Value(totalChapters),
            finalVolume: Value(finalVolume),
          ),
        );
    await db.into(db.libraryEntriesTable).insert(
          LibraryEntriesTableCompanion.insert(
            id: 'entry-$seriesId',
            seriesId: seriesId,
            state: state,
            progressChapter: Value(chapter),
            progressVolume: Value(volume),
          ),
        );
  }

  Future<LibraryEntriesTableData?> entryFor(String seriesId) async =>
      (await db.libraryEntriesDao.getEntryBySeriesId(seriesId))?.libraryEntry;

  final entryUrl = '${LibraryConstants.baseUrl}/42';

  group('updateLibraryEntryState', () {
    test('PUTs the state with the bearer token and updates the local entry',
        () async {
      await seedEntry('42');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState('42', 'completed'),
      );

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.toString(), entryUrl);
      expect(requests.single.headers['Authorization'], 'Bearer old');
      expect(jsonDecode(requests.single.body), {'state': 'completed'});
      expect((await entryFor('42'))!.state, 'completed');
    });

    test('a server error leaves the local entry alone', () async {
      await seedEntry('42');

      await expectLater(
        withServer(
          (_) async => http.Response('boom', 500),
          () => service.updateLibraryEntryState('42', 'completed'),
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'UPDATE_STATE_FAILED')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
      expect((await entryFor('42'))!.state, 'reading');
    });

    test('recovers from a revoked token by refreshing and retrying', () async {
      await seedEntry('42');

      await withServer(
        (r) async => http.Response('{}', bearerIsNew(r) ? 200 : 401),
        () => service.updateLibraryEntryState('42', 'dropped'),
      );

      expect(refreshCalls, 1);
      expect(
        requests.map((r) => r.headers['Authorization']),
        ['Bearer old', 'Bearer new'],
      );
      expect((await entryFor('42'))!.state, 'dropped');
    });

    test('a dead session surfaces as SessionExpiredException', () async {
      await seedEntry('42');
      auth = ProfileAuthService(
        storage: storage,
        network: FakeAuthNetwork(),
        refresher: (_) async => throw ApiException(
          message: 'invalid_grant',
          statusCode: 400,
        ),
      );
      service = LibraryService(auth: auth, database: db);

      await expectLater(
        withServer(
          (_) async => http.Response('', 401),
          () => service.updateLibraryEntryState('42', 'dropped'),
        ),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(storage.values[AuthStorage.kAccessToken], isNull);
      expect((await entryFor('42'))!.state, 'reading');
    });

    test(
        'auto-sets progress_chapter from DB totalChapters when marking completed in always mode',
        () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteChapterProgress(
        AutoCompleteProgressMode.always,
      );
      await seedEntry('42', chapter: 10, totalChapters: '83');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState('42', 'completed'),
      );

      expect(jsonDecode(requests.single.body), {
        'state': 'completed',
        'progress_chapter': 83,
      });
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 83);
    });

    test(
        'auto-sets progress_chapter from explicit totalChapters when marking completed in always mode',
        () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteChapterProgress(
        AutoCompleteProgressMode.always,
      );
      await seedEntry('42', chapter: 5);

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState(
          '42',
          'completed',
          totalChapters: 50,
        ),
      );

      expect(jsonDecode(requests.single.body), {
        'state': 'completed',
        'progress_chapter': 50,
      });
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 50);
    });

    test(
        'does not overwrite progress_chapter when already at or above totalChapters',
        () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteChapterProgress(
        AutoCompleteProgressMode.always,
      );
      await seedEntry('42', chapter: 85, totalChapters: '83');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState('42', 'completed'),
      );

      expect(jsonDecode(requests.single.body), {'state': 'completed'});
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 85);
    });

    test(
        'leaves state and progressChapter untouched when completing fails on server',
        () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteChapterProgress(
        AutoCompleteProgressMode.always,
      );
      await seedEntry('42', chapter: 10, totalChapters: '83');

      await expectLater(
        withServer(
          (_) async => http.Response('boom', 500),
          () => service.updateLibraryEntryState('42', 'completed'),
        ),
        throwsA(isA<ApiException>()),
      );

      final existing = (await entryFor('42'))!;
      expect(existing.state, 'reading');
      expect(existing.progressChapter, 10);
    });

    test(
        'does not auto-set progress_chapter when autoCompleteChapterProgress is never',
        () async {
      await SettingsManager().init();
      await SettingsManager().setAutoCompleteChapterProgress(
        AutoCompleteProgressMode.never,
      );
      await seedEntry('42', chapter: 10, totalChapters: '83');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState('42', 'completed'),
      );

      expect(jsonDecode(requests.single.body), {'state': 'completed'});
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 10);
    });

    test(
        'does not auto-set progress in default prompt mode unless explicitly confirmed',
        () async {
      await SettingsManager().init();
      expect(
        SettingsManager().autoCompleteChapterProgress,
        AutoCompleteProgressMode.prompt,
      );
      await seedEntry(
        '42',
        chapter: 10,
        totalChapters: '83',
        volume: 2,
        finalVolume: '16',
      );

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState('42', 'completed'),
      );

      expect(jsonDecode(requests.single.body), {'state': 'completed'});
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 10);
      expect(updated.progressVolume, 2);
    });

    test(
        'sets both progress_chapter and progress_volume when completeChapters and completeVolumes are true',
        () async {
      await SettingsManager().init();
      await seedEntry(
        '42',
        chapter: 10,
        totalChapters: '83',
        volume: 2,
        finalVolume: '16',
      );

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryState(
          '42',
          'completed',
          completeChapters: true,
          completeVolumes: true,
        ),
      );

      expect(jsonDecode(requests.single.body), {
        'state': 'completed',
        'progress_chapter': 83,
        'progress_volume': 16,
      });
      final updated = (await entryFor('42'))!;
      expect(updated.state, 'completed');
      expect(updated.progressChapter, 83);
      expect(updated.progressVolume, 16);
    });
  });

  group('updateLibraryEntryProgress', () {
    test('keeps the optimistic value when the server accepts it', () async {
      await seedEntry('42', chapter: 5);

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryProgress('42', progressChapter: 6),
      );

      expect(jsonDecode(requests.single.body), {'progress_chapter': 6});
      expect((await entryFor('42'))!.progressChapter, 6);
    });

    test('rolls the local value back when the server rejects it', () async {
      await seedEntry('42', chapter: 5);

      await expectLater(
        withServer(
          (_) async => http.Response('bad', 422),
          () => service.updateLibraryEntryProgress('42', progressChapter: 6),
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'UPDATE_PROGRESS_FAILED')),
      );
      expect((await entryFor('42'))!.progressChapter, 5);
    });

    test('does not roll back over a newer update that landed meanwhile',
        () async {
      await seedEntry('42', chapter: 5);

      await expectLater(
        withServer(
          (_) async {
            // A later +1 wrote 7 while this request was in flight.
            await db.libraryEntriesDao
                .updateEntryProgress('42', progressChapter: 7);
            return http.Response('bad', 500);
          },
          () => service.updateLibraryEntryProgress('42', progressChapter: 6),
        ),
        throwsA(isA<ApiException>()),
      );
      expect((await entryFor('42'))!.progressChapter, 7);
    });
  });

  group('deleteEntry', () {
    test('removes the local entry when the server already lost it (404)',
        () async {
      await seedEntry('42');

      await withServer(
        (_) async => http.Response('', 404),
        () => service.deleteEntry('42'),
      );

      expect(requests.single.method, 'DELETE');
      expect(requests.single.headers.containsKey('Content-Type'), isFalse);
      expect(await entryFor('42'), isNull);
    });

    test('keeps the local entry when the server refuses', () async {
      await seedEntry('42');

      await expectLater(
        withServer(
          (_) async => http.Response('', 500),
          () => service.deleteEntry('42'),
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'DELETE_ENTRY_FAILED')),
      );
      expect(await entryFor('42'), isNotNull);
    });
  });

  group('createLibraryEntriesBatch', () {
    test('sends numeric ids in chunks of 100 and counts created entries',
        () async {
      final ids = [for (var i = 1; i <= 150; i++) '$i', 'not-a-number'];

      final created = await withServer(
        (r) async {
          if (r.method == 'GET') {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          final chunk = jsonDecode(r.body) as List;
          return http.Response(
            jsonEncode({
              'data': [
                for (final _ in chunk) {'action': 'created'},
              ],
            }),
            200,
          );
        },
        () => service.createLibraryEntriesBatch(ids, 'plan_to_read'),
      );

      final posts = requests.where((r) => r.method == 'POST').toList();
      expect(posts, hasLength(2));
      expect((jsonDecode(posts[0].body) as List), hasLength(100));
      expect((jsonDecode(posts[1].body) as List), hasLength(50));
      expect(
        (jsonDecode(posts[0].body) as List).first,
        {'series_id': 1, 'state': 'plan_to_read'},
      );
      expect(created, 150);
      // Accepted chunks are followed by a sync to pull the new entries.
      expect(requests.any((r) => r.method == 'GET'), isTrue);
    });
  });

  group('library sync', () {
    test('a rejected page marks the library incomplete and keeps the '
        'watermark', () async {
      await withServer(
        (_) async => http.Response('bad request', 400),
        () => service.syncLibrary(),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(await service.isLibraryIncomplete(), isTrue);
      expect(prefs.getString(AppConstants.lastSyncKey), isNull);
      expect(service.syncStatus.value.isSyncing, isFalse);
    });

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
      }) =>
          http.Response(
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

      test('the first sync scans from the start and stores the cursor',
          () async {
        await withServer(server, () => service.syncLibrary());
        final changes = requests.firstWhere((r) => r.url.path.endsWith('/changes'));
        expect(changes.url.queryParameters.containsKey('cursor'), isFalse);
        expect(changes.url.queryParameters['limit'], '1000');
        expect((await entryFor('42'))!.rating, 9);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.libraryCursorKey), 'c1');
        expect(await service.isLibraryIncomplete(), isFalse);
      });

      test('a later sync sends the stored cursor', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'saved',
          librarySeriesDataKey: librarySeriesDataVersion,
        });
        await withServer((_) async => feed([], cursor: 'next'), () => service.syncLibrary());
        expect(requests.single.url.queryParameters['cursor'], 'saved');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.libraryCursorKey), 'next');
      });

      test('series are fetched from v1, which carries the canonical titles',
          () async {
        await withServer(server, () => service.syncLibrary());
        final batchRequest =
            requests.firstWhere((r) => r.url.path.endsWith('/series/batch'));
        expect(batchRequest.url.path, startsWith('/v1/'));
      });

      test('series stored by an older data generation are re-fetched once',
          () async {
        // A row as the old v2-based sync stored it, under a saved cursor.
        await seedEntry('42');
        await (db.update(db.seriesTable)..where((t) => t.id.equals('42')))
            .write(const SeriesTableCompanion(title: Value('Guessed title')));
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'saved',
        });

        await withServer(server, () => service.syncLibrary());

        // The cursor is dropped for a full scan, and the stored row replaced.
        final changes =
            requests.firstWhere((r) => r.url.path.endsWith('/changes'));
        expect(changes.url.queryParameters.containsKey('cursor'), isFalse);
        final row = await (db.select(db.seriesTable)
              ..where((t) => t.id.equals('42')))
            .getSingle();
        expect(row.title, 'Series 42');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(librarySeriesDataKey), librarySeriesDataVersion);

        // Done once: the next sync is incremental again.
        requests.clear();
        await withServer(
          (_) async => feed([], cursor: 'c2'),
          () => service.syncLibrary(),
        );
        expect(requests.single.url.queryParameters['cursor'], 'c1');
      });

      test('a delete removes the entry', () async {
        await seedEntry('42');
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'saved',
        });
        await withServer(
          (_) async => feed([
            {
              'type': 'entry',
              'action': 'delete',
              'current': {'series_id': 42},
            },
          ]),
          () => service.syncLibrary(),
        );
        expect(await entryFor('42'), isNull);
      });

      test('a rejected cursor rescans from the start', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.libraryCursorKey: 'stale',
        });
        await withServer(
          (r) async => r.url.path.endsWith('/series/batch')
              ? batch([42])
              : r.url.queryParameters['cursor'] == 'stale'
              ? http.Response('bad cursor', 400)
              : feed([entryItem(42)], cursor: 'fresh'),
          () => service.syncLibrary(),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.libraryCursorKey), 'fresh');
        expect(await entryFor('42'), isNotNull);
      });

      test('a full scan drops local entries the server no longer lists',
          () async {
        await seedEntry('7');
        await withServer(server, () => service.syncLibrary(deep: true));
        expect(await entryFor('7'), isNull);
        expect(await entryFor('42'), isNotNull);
      });
    });

    test('a page fetch recovers from a revoked token', () async {
      await withServer(
        (r) async => bearerIsNew(r)
            ? http.Response(jsonEncode({'data': []}), 200)
            : http.Response('', 401),
        () => service.syncLibrary(),
      );

      expect(refreshCalls, 1);
      expect(service.syncStatus.value.error, isNull);
    });

    group('autoCompleteSeriesStatus', () {
      test(
          'auto-completes state and volumes when chapter reaches total on completed series with always mode',
          () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 82,
          totalChapters: '83',
          volume: 10,
          finalVolume: '16',
        );

        await withServer(
          (_) async => http.Response('{}', 200),
          () => service.updateLibraryEntryProgress('42', progressChapter: 83),
        );

        expect(jsonDecode(requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
          'progress_volume': 16,
        });
        final updated = (await entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 16);
      });

      test(
          'auto-completes state and chapters when volume reaches total on completed series with always mode',
          () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 50,
          totalChapters: '83',
          volume: 15,
          finalVolume: '16',
        );

        await withServer(
          (_) async => http.Response('{}', 200),
          () => service.updateLibraryEntryProgress('42', progressVolume: 16),
        );

        expect(jsonDecode(requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
          'progress_volume': 16,
        });
        final updated = (await entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 16);
      });

      test('does not auto-complete when series is not completed', () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await seedEntry(
          '42',
          seriesStatus: 'releasing',
          chapter: 82,
          totalChapters: '83',
          volume: 10,
          finalVolume: '16',
        );

        await withServer(
          (_) async => http.Response('{}', 200),
          () => service.updateLibraryEntryProgress('42', progressChapter: 83),
        );

        expect(jsonDecode(requests.single.body), {'progress_chapter': 83});
        final updated = (await entryFor('42'))!;
        expect(updated.state, 'reading');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 10);
      });

      test('rolls back state, chapter, and volume when server fails',
          () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.always,
        );
        await seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 82,
          totalChapters: '83',
          volume: 10,
          finalVolume: '16',
        );

        await expectLater(
          withServer(
            (_) async => http.Response('boom', 500),
            () => service.updateLibraryEntryProgress('42', progressChapter: 83),
          ),
          throwsA(isA<ApiException>()),
        );

        final rolledBack = (await entryFor('42'))!;
        expect(rolledBack.state, 'reading');
        expect(rolledBack.progressChapter, 82);
        expect(rolledBack.progressVolume, 10);
      });

      test('does not auto-complete in prompt or never mode', () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteSeriesStatus(
          AutoCompleteProgressMode.never,
        );
        await seedEntry(
          '42',
          seriesStatus: 'completed',
          chapter: 82,
          totalChapters: '83',
          volume: 10,
          finalVolume: '16',
        );

        await withServer(
          (_) async => http.Response('{}', 200),
          () => service.updateLibraryEntryProgress('42', progressChapter: 83),
        );

        expect(jsonDecode(requests.single.body), {'progress_chapter': 83});
        final updated = (await entryFor('42'))!;
        expect(updated.state, 'reading');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 10);
      });
    });
  });

  group('updateLibraryEntryNote', () {
    test('PUTs trimmed note with bearer token and updates the local entry',
        () async {
      await seedEntry('42');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryNote('42', '  **Great** arc!  '),
      );

      expect(requests.single.method, 'PUT');
      expect(requests.single.url, Uri.parse('${LibraryConstants.baseUrl}/42'));
      expect(requests.single.headers['Authorization'], 'Bearer old');
      expect(jsonDecode(requests.single.body), {'note': '**Great** arc!'});
      expect((await entryFor('42'))!.note, '**Great** arc!');
    });

    test('normalizes blank note to null and clears the local entry', () async {
      await seedEntry('42');
      await db.libraryEntriesDao.updateEntryNote('42', 'Existing note');

      await withServer(
        (_) async => http.Response('{}', 200),
        () => service.updateLibraryEntryNote('42', '   \n  '),
      );

      expect(jsonDecode(requests.single.body), {'note': null});
      expect((await entryFor('42'))!.note, isNull);
    });

    test('a server error leaves the local note untouched', () async {
      await seedEntry('42');
      await db.libraryEntriesDao.updateEntryNote('42', 'Keep me');

      await expectLater(
        withServer(
          (_) async => http.Response('boom', 500),
          () => service.updateLibraryEntryNote('42', 'New note'),
        ),
        throwsA(isA<ApiException>()),
      );

      expect((await entryFor('42'))!.note, 'Keep me');
    });
  });
}
