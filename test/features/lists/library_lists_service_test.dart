import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/auth_test_helpers.dart';

void main() {
  late AppDatabase db;
  late ProfileAuthService auth;
  late LibraryListsService service;
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Map<String, dynamic> listJson(int id, String name, {bool private = false}) =>
      {
        'id': id,
        'name': name,
        'is_private': private,
        'series_count': 0,
        'created_at': '2026-11-0${id % 9 + 1}T10:00:00.000Z',
        'updated_at': null,
      };

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final storage = MemoryAuthStorage();
    seedSession(storage, access: 'tok');
    auth = ProfileAuthService(
      storage: storage,
      network: FakeAuthNetwork(),
      refresher: (_) async => tokens('new', refresh: 'r2'),
    );
    await auth.init();
    requests = [];
    handler = (_) => json({'status': 200, 'data': []});
    service = LibraryListsService(
      database: db,
      client: MockClient((r) async {
        requests.add(r);
        return handler(r);
      }),
      auth: () => auth,
    );
  });

  tearDown(() async {
    await db.close();
    await resetServiceLocator();
  });

  Future<List<LibraryListsTableData>> stored() => db.libraryListsDao.getLists();

  Future<Map<String, Set<int>>> members() async {
    final out = <String, Set<int>>{};
    for (final r in await db.select(db.libraryListEntriesTable).get()) {
      (out[r.seriesId] ??= {}).add(r.listId);
    }
    return out;
  }

  test('refresh follows pages and replaces the local lists', () async {
    await db.libraryListsDao.upsertLists([
      const LibraryListsTableCompanion(id: Value(99), name: Value('Gone')),
    ]);
    handler = (r) => r.url.queryParameters['page'] == '1'
        ? json({
            'status': 200,
            'data': [listJson(1, 'A')],
            'pagination': {'count': 2, 'page': 1, 'next': 'https://x/2'},
          })
        : json({
            'status': 200,
            'data': [listJson(2, 'B', private: true)],
            'pagination': {'count': 2, 'page': 2, 'next': null},
          });

    await service.refresh();

    expect(requests.map((r) => r.url.queryParameters['page']), ['1', '2']);
    expect(requests.first.url.queryParameters['limit'], '1000');
    expect(requests.first.headers['Authorization'], 'Bearer tok');
    final lists = await stored();
    expect(
      {for (final l in lists) l.id: (l.name, l.isPrivate)},
      {1: ('A', false), 2: ('B', true)},
    );
    expect(lists.first.createdAt, isNotNull);
  });

  test('create sends the normalised name and mirrors the answer', () async {
    handler = (_) => json({'status': 200, 'data': listJson(7, 'Train reads')});

    final created = await service.create('  Train \n reads ', isPrivate: true);

    final r = requests.single;
    expect(r.method, 'POST');
    expect(r.url.path, '/v2/my/library/lists');
    expect(jsonDecode(r.body), {'name': 'Train reads', 'is_private': true});
    expect(created.id, 7);
    expect((await stored()).single.name, 'Train reads');
  });

  test('edit sends only the fields it was given', () async {
    handler = (_) =>
        json({'status': 200, 'data': listJson(3, 'C', private: true)});

    await service.edit(3, isPrivate: true);

    expect(requests.single.method, 'PATCH');
    expect(requests.single.url.path, '/v2/my/library/lists/3');
    expect(jsonDecode(requests.single.body), {'is_private': true});
  });

  test('delete drops the list and its memberships locally', () async {
    await db.libraryListsDao.upsertLists([
      const LibraryListsTableCompanion(id: Value(4), name: Value('D')),
    ]);
    await db.libraryListsDao.setMemberships({
      '42': {4},
    });
    handler = (_) => json({'status': 200});

    await service.delete(4);

    expect(requests.single.method, 'DELETE');
    expect(await stored(), isEmpty);
    expect(await members(), isEmpty);
  });

  test('batch privacy goes out in chunks of 100', () async {
    handler = (_) => json({
      'status': 200,
      'data': {'updated': 1, 'skipped': 0},
    });
    final ids = [for (var i = 1; i <= 150; i++) i];

    await service.setPrivateMany(ids, isPrivate: true);

    expect(requests, hasLength(2));
    final first = jsonDecode(requests.first.body) as Map;
    expect(first['action'], 'set_visibility');
    expect((first['ids'] as List), hasLength(100));
    expect(first['is_private'], isTrue);
    expect((jsonDecode(requests.last.body)['ids'] as List), hasLength(50));
  });

  test('membership changes mirror every list the answer names', () async {
    handler = (_) => json({
      'status': 200,
      'data': [
        {'id': 1, 'name': 'A', 'is_private': false},
        {'id': 2, 'name': 'B', 'is_private': true},
      ],
    });

    final ids = await service.setMembership('42', 2, member: true);

    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/v2/my/library/42/lists/2');
    expect(ids, {1, 2});
    expect(await members(), {
      '42': {1, 2},
    });
    expect((await stored()).map((l) => l.id).toSet(), {1, 2});
  });

  test('a refused write leaves the local copy alone', () async {
    handler = (_) => json({'status': 400, 'message': 'Bad Request'}, 400);

    await expectLater(
      service.create('Favourites'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
    expect(await stored(), isEmpty);
  });

  test('signed out, nothing is sent', () async {
    final signedOut = ProfileAuthService(
      storage: MemoryAuthStorage(),
      network: FakeAuthNetwork(),
      refresher: (_) async => tokens('new', refresh: 'r2'),
    );
    await signedOut.init();
    final offline = LibraryListsService(
      database: db,
      client: MockClient((r) async {
        requests.add(r);
        return handler(r);
      }),
      auth: () => signedOut,
    );
    await expectLater(
      offline.create('A'),
      throwsA(isA<SessionExpiredException>()),
    );
    expect(requests, isEmpty);
  });
}
