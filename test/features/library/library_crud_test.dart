import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

import '../profile/auth_test_helpers.dart';
import 'library_crud_test_harness.dart';

void main() {
  final h = LibraryCrudTestHarness();

  setUp(h.setUp);
  tearDown(h.tearDown);

  group('updateLibraryEntryState', () {
    test(
      'PUTs the state with the bearer token and updates the local entry',
      () async {
        await h.seedEntry('42');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        );

        expect(h.requests.single.method, 'PUT');
        expect(h.requests.single.url.toString(), h.entryUrl);
        expect(h.requests.single.headers['Authorization'], 'Bearer old');
        expect(jsonDecode(h.requests.single.body), {'state': 'completed'});
        expect((await h.entryFor('42'))!.state, 'completed');
      },
    );

    test('a server error leaves the local entry alone', () async {
      await h.seedEntry('42');

      await expectLater(
        h.withServer(
          (_) async => http.Response('boom', 500),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'UPDATE_STATE_FAILED')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
      expect((await h.entryFor('42'))!.state, 'reading');
    });

    test('recovers from a revoked token by refreshing and retrying', () async {
      await h.seedEntry('42');

      await h.withServer(
        (r) async => http.Response('{}', h.bearerIsNew(r) ? 200 : 401),
        () => h.service.updateLibraryEntryState('42', 'dropped'),
      );

      expect(h.refreshCalls, 1);
      expect(h.requests.map((r) => r.headers['Authorization']), [
        'Bearer old',
        'Bearer new',
      ]);
      expect((await h.entryFor('42'))!.state, 'dropped');
    });

    test('a dead session surfaces as SessionExpiredException', () async {
      await h.seedEntry('42');
      h.auth = ProfileAuthService(
        storage: h.storage,
        network: FakeAuthNetwork(),
        refresher: (_) async =>
            throw ApiException(message: 'invalid_grant', statusCode: 400),
      );
      h.service = LibraryService(auth: h.auth, database: h.db);

      await expectLater(
        h.withServer(
          (_) async => http.Response('', 401),
          () => h.service.updateLibraryEntryState('42', 'dropped'),
        ),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(h.storage.values[AuthStorage.kAccessToken], isNull);
      expect((await h.entryFor('42'))!.state, 'reading');
    });

    test(
      'auto-sets progress_chapter from DB totalChapters when marking completed in always mode',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteChapterProgress(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry('42', chapter: 10, totalChapters: '83');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        );

        expect(jsonDecode(h.requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
        });
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
      },
    );

    test(
      'auto-sets progress_chapter from explicit totalChapters when marking completed in always mode',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteChapterProgress(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry('42', chapter: 5);

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState(
            '42',
            'completed',
            totalChapters: 50,
          ),
        );

        expect(jsonDecode(h.requests.single.body), {
          'state': 'completed',
          'progress_chapter': 50,
        });
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 50);
      },
    );

    test(
      'does not overwrite progress_chapter when already at or above totalChapters',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteChapterProgress(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry('42', chapter: 85, totalChapters: '83');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        );

        expect(jsonDecode(h.requests.single.body), {'state': 'completed'});
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 85);
      },
    );

    test(
      'leaves state and progressChapter untouched when completing fails on server',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteChapterProgress(
          AutoCompleteProgressMode.always,
        );
        await h.seedEntry('42', chapter: 10, totalChapters: '83');

        await expectLater(
          h.withServer(
            (_) async => http.Response('boom', 500),
            () => h.service.updateLibraryEntryState('42', 'completed'),
          ),
          throwsA(isA<ApiException>()),
        );

        final existing = (await h.entryFor('42'))!;
        expect(existing.state, 'reading');
        expect(existing.progressChapter, 10);
      },
    );

    test(
      'does not auto-set progress_chapter when autoCompleteChapterProgress is never',
      () async {
        await SettingsManager().init();
        await SettingsManager().setAutoCompleteChapterProgress(
          AutoCompleteProgressMode.never,
        );
        await h.seedEntry('42', chapter: 10, totalChapters: '83');

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        );

        expect(jsonDecode(h.requests.single.body), {'state': 'completed'});
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 10);
      },
    );

    test(
      'does not auto-set progress in default prompt mode unless explicitly confirmed',
      () async {
        await SettingsManager().init();
        expect(
          SettingsManager().autoCompleteChapterProgress,
          AutoCompleteProgressMode.prompt,
        );
        await h.seedEntry(
          '42',
          chapter: 10,
          totalChapters: '83',
          volume: 2,
          finalVolume: '16',
        );

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState('42', 'completed'),
        );

        expect(jsonDecode(h.requests.single.body), {'state': 'completed'});
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 10);
        expect(updated.progressVolume, 2);
      },
    );

    test(
      'sets both progress_chapter and progress_volume when completeChapters and completeVolumes are true',
      () async {
        await SettingsManager().init();
        await h.seedEntry(
          '42',
          chapter: 10,
          totalChapters: '83',
          volume: 2,
          finalVolume: '16',
        );

        await h.withServer(
          (_) async => http.Response('{}', 200),
          () => h.service.updateLibraryEntryState(
            '42',
            'completed',
            completeChapters: true,
            completeVolumes: true,
          ),
        );

        expect(jsonDecode(h.requests.single.body), {
          'state': 'completed',
          'progress_chapter': 83,
          'progress_volume': 16,
        });
        final updated = (await h.entryFor('42'))!;
        expect(updated.state, 'completed');
        expect(updated.progressChapter, 83);
        expect(updated.progressVolume, 16);
      },
    );
  });
}
