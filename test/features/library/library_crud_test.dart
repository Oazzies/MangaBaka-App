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
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
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
    int? chapter,
  }) async {
    await db.into(db.seriesTable).insert(
          SeriesTableCompanion.insert(
            id: seriesId,
            title: 'Series $seriesId',
            coverUrl: 'url',
            description: 'desc',
          ),
        );
    await db.into(db.libraryEntriesTable).insert(
          LibraryEntriesTableCompanion.insert(
            id: 'entry-$seriesId',
            seriesId: seriesId,
            state: state,
            progressChapter: Value(chapter),
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
  });
}
