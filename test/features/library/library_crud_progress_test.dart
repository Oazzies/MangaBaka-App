import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';

import 'library_crud_test_harness.dart';

void main() {
  final h = LibraryCrudTestHarness();

  setUp(h.setUp);
  tearDown(h.tearDown);

  group('updateLibraryEntryProgress', () {
    test('keeps the optimistic value when the server accepts it', () async {
      await h.seedEntry('42', chapter: 5);

      await h.withServer(
        (_) async => http.Response('{}', 200),
        () => h.service.updateLibraryEntryProgress('42', progressChapter: 6),
      );

      expect(jsonDecode(h.requests.single.body), {'progress_chapter': 6});
      expect((await h.entryFor('42'))!.progressChapter, 6);
    });

    test('rolls the local value back when the server rejects it', () async {
      await h.seedEntry('42', chapter: 5);

      await expectLater(
        h.withServer(
          (_) async => http.Response('bad', 422),
          () => h.service.updateLibraryEntryProgress('42', progressChapter: 6),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'UPDATE_PROGRESS_FAILED',
          ),
        ),
      );
      expect((await h.entryFor('42'))!.progressChapter, 5);
    });

    test(
      'does not roll back over a newer update that landed meanwhile',
      () async {
        await h.seedEntry('42', chapter: 5);

        await expectLater(
          h.withServer(
            (_) async {
              await h.db.libraryEntriesDao.updateEntryProgress(
                '42',
                progressChapter: 7,
              );
              return http.Response('bad', 500);
            },
            () => h.service.updateLibraryEntryProgress('42', progressChapter: 6),
          ),
          throwsA(isA<ApiException>()),
        );
        expect((await h.entryFor('42'))!.progressChapter, 7);
      },
    );
  });

  group('deleteEntry', () {
    test(
      'removes the local entry when the server already lost it (404)',
      () async {
        await h.seedEntry('42');

        await h.withServer(
          (_) async => http.Response('', 404),
          () => h.service.deleteEntry('42'),
        );

        expect(h.requests.single.method, 'DELETE');
        expect(h.requests.single.headers.containsKey('Content-Type'), isFalse);
        expect(await h.entryFor('42'), isNull);
      },
    );

    test('keeps the local entry when the server refuses', () async {
      await h.seedEntry('42');

      await expectLater(
        h.withServer(
          (_) async => http.Response('', 500),
          () => h.service.deleteEntry('42'),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'DELETE_ENTRY_FAILED',
          ),
        ),
      );
      expect(await h.entryFor('42'), isNotNull);
    });
  });

  group('createLibraryEntriesBatch', () {
    test(
      'sends numeric ids in chunks of 100 and counts created entries',
      () async {
        final ids = [for (var i = 1; i <= 150; i++) '$i', 'not-a-number'];

        final created = await h.withServer(
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
          () => h.service.createLibraryEntriesBatch(ids, 'plan_to_read'),
        );

        final posts = h.requests.where((r) => r.method == 'POST').toList();
        expect(posts, hasLength(2));
        expect((jsonDecode(posts[0].body) as List), hasLength(100));
        expect((jsonDecode(posts[1].body) as List), hasLength(50));
        expect((jsonDecode(posts[0].body) as List).first, {
          'series_id': 1,
          'state': 'plan_to_read',
        });
        expect(created, 150);
        expect(h.requests.any((r) => r.method == 'GET'), isTrue);
      },
    );
  });

  group('updateLibraryEntryNote', () {
    test(
      'PUTs trimmed note with bearer token and updates the local entry',
      () async {
        await h.seedEntry('42');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryNote('42', '  **Great** arc!  '),
        );

        expect(h.requests.single.method, 'PUT');
        expect(
          h.requests.single.url,
          Uri.parse('${LibraryConstants.baseUrl}/42'),
        );
        expect(h.requests.single.headers['Authorization'], 'Bearer old');
        expect(jsonDecode(h.requests.single.body), {'note': '**Great** arc!'});
        expect((await h.entryFor('42'))!.note, '**Great** arc!');
      },
    );

    test(
      'normalizes blank note to null and clears the local entry',
      () async {
        await h.seedEntry('42');
        await h.db.libraryEntriesDao.updateEntryNote('42', 'Existing note');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryNote('42', '   \n  '),
        );

        expect(jsonDecode(h.requests.single.body), {'note': null});
        expect((await h.entryFor('42'))!.note, isNull);
      },
    );

    test('a server error leaves the local note untouched', () async {
      await h.seedEntry('42');
      await h.db.libraryEntriesDao.updateEntryNote('42', 'Keep me');

      await expectLater(
        h.withServer(
          (_) async => http.Response('boom', 500),
          () => h.service.updateLibraryEntryNote('42', 'New note'),
        ),
        throwsA(isA<ApiException>()),
      );

      expect((await h.entryFor('42'))!.note, 'Keep me');
    });
  });
}
