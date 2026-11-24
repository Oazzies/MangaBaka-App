import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_mixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'library_crud_test_harness.dart';

void main() {
  final h = LibraryCrudTestHarness();

  setUp(h.setUp);
  tearDown(h.tearDown);

  Map<String, dynamic> entry(int seriesId, List<int> lists) => {
    'type': 'entry',
    'action': 'upsert',
    'revision': 1,
    'current': {
      'id': 1000 + seriesId,
      'series_id': seriesId,
      'state': 'reading',
      'list_ids': lists,
    },
  };

  Map<String, dynamic> list(int id, String name, {bool private = false}) => {
    'type': 'list',
    'action': 'upsert',
    'revision': 1,
    'current': {'id': id, 'name': name, 'is_private': private},
  };

  http.Response feed(List<Map<String, dynamic>> items, {String cursor = 'c'}) =>
      http.Response(
        jsonEncode({
          'data': items,
          'pagination': {'limit': 1000, 'cursor': cursor, 'more': false},
        }),
        200,
      );

  Future<http.Response> Function(http.Request) server(
    List<Map<String, dynamic>> items,
  ) =>
      (r) async => r.url.path.endsWith('/series/batch')
      ? http.Response(
          jsonEncode({
            'data': [
              for (final id in r.url.queryParametersAll['id']!)
                {'id': int.parse(id), 'title': 'Series $id'},
            ],
          }),
          200,
        )
      : feed(items);

  Future<Map<String, Set<int>>> memberships() async {
    final rows = await h.db.select(h.db.libraryListEntriesTable).get();
    final out = <String, Set<int>>{};
    for (final r in rows) {
      (out[r.seriesId] ??= {}).add(r.listId);
    }
    return out;
  }

  test('lists and entry list ids from the feed are stored', () async {
    await h.withServer(
      server([
        list(1, 'Favourites'),
        list(2, 'Train', private: true),
        entry(42, [1, 2]),
        entry(43, []),
      ]),
      () => h.service.syncLibrary(),
    );

    final lists = await h.db.libraryListsDao.getLists();
    expect(
      {for (final l in lists) l.id: (l.name, l.isPrivate)},
      {1: ('Favourites', false), 2: ('Train', true)},
    );
    expect(await memberships(), {
      '42': {1, 2},
    });
  });

  test('a list delete removes the list and its memberships', () async {
    await h.withServer(
      server([
        list(1, 'A'),
        list(2, 'B'),
        entry(42, [1, 2]),
      ]),
      () => h.service.syncLibrary(),
    );
    await h.withServer(
      server([
        {
          'type': 'list',
          'action': 'delete',
          'current': {'id': 2},
        },
      ]),
      () => h.service.syncLibrary(),
    );

    final lists = await h.db.libraryListsDao.getLists();
    expect(lists.map((l) => l.id), [1]);
    expect(await memberships(), {
      '42': {1},
    });
  });

  test('an entry delete drops its memberships', () async {
    await h.withServer(
      server([
        list(1, 'A'),
        entry(42, [1]),
      ]),
      () => h.service.syncLibrary(),
    );
    await h.withServer(
      server([
        {
          'type': 'entry',
          'action': 'delete',
          'current': {'series_id': 42},
        },
      ]),
      () => h.service.syncLibrary(),
    );
    expect(await memberships(), isEmpty);
  });

  test('a full scan prunes lists the server no longer has', () async {
    await h.withServer(
      server([
        list(1, 'A'),
        list(2, 'B'),
        entry(42, [1, 2]),
      ]),
      () => h.service.syncLibrary(),
    );
    await h.withServer(
      server([
        list(1, 'A'),
        entry(42, [1]),
      ]),
      () => h.service.syncLibrary(deep: true),
    );
    final lists = await h.db.libraryListsDao.getLists();
    expect(lists.map((l) => l.id), [1]);
  });

  test('a stored cursor from before lists is ignored once', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.libraryCursorKey: 'old',
      librarySeriesDataKey: librarySeriesDataVersion,
    });
    await h.withServer(
      server([
        list(1, 'A'),
        entry(42, [1]),
      ]),
      () => h.service.syncLibrary(),
    );
    final first = h.requests.firstWhere((r) => r.url.path.endsWith('/changes'));
    expect(first.url.queryParameters.containsKey('cursor'), isFalse);
    expect(
      h.requests.where((r) => r.url.path.endsWith('/series/batch')),
      isNotEmpty,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(libraryFeedDataKey), libraryFeedDataVersion);

    h.requests.clear();
    await h.withServer(server([]), () => h.service.syncLibrary());
    expect(h.requests.single.url.queryParameters['cursor'], 'c');
  });

  test('clearing the library clears lists', () async {
    await h.withServer(
      server([
        list(1, 'A'),
        entry(42, [1]),
      ]),
      () => h.service.syncLibrary(),
    );
    await h.service.clearLibrary();
    expect(await h.db.libraryListsDao.getLists(), isEmpty);
    expect(await memberships(), isEmpty);
  });
}
