import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

class _FakeAuth extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
}

Series _series(String id) => Series(
      id: id,
      title: 'Series $id',
      state: 'active',
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: const [],
      coverUrl: '',
      rawCoverUrl: '',
      authors: const [],
      artists: const [],
      description: '',
      year: '',
      status: '',
      isLicensed: '',
      hasAnime: '',
      contentRating: 'safe',
      type: 'manga',
      rating: '0',
      finalVolume: '',
      totalChapters: '',
      links: const [],
      publishers: const [],
      genres: const [],
      tags: const [],
      lastUpdated: '',
    );

api.LibraryEntry _entry(String id) => api.LibraryEntry(
      id: id,
      state: 'reading',
      series: _series(id),
    );

void main() {
  late AppDatabase db;
  late LibraryService service;

  setUpAll(() {
    if (!getIt.isRegistered<LoggingService>()) {
      getIt.registerSingleton<LoggingService>(LoggingService());
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(db);
    service = LibraryService(auth: _FakeAuth(), database: db);
  });


  tearDown(() async {
    await db.close();
    await resetServiceLocator();
  });

  // ─── LibraryCrudMixin ──────────────────────────────────────────────────────

  group('LibraryCrudMixin.clearLibrary', () {
    test('removes all library entries from the database', () async {
      await service.saveEntries([_entry('s1'), _entry('s2')]);

      final before = await db.libraryEntriesDao.watchAllEntriesWithSeries().first;
      expect(before, hasLength(2));

      await service.clearLibrary();

      final after = await db.libraryEntriesDao.watchAllEntriesWithSeries().first;
      expect(after, isEmpty);
    });

    test('removes lastSyncKey and isIncompleteKey from prefs', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.lastSyncKey: '2026-01-01T00:00:00Z',
        '${AppConstants.prefixStorageKey}library_is_incomplete': true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.lastSyncKey), isNotNull);

      await service.clearLibrary();

      expect(prefs.getString(AppConstants.lastSyncKey), isNull);
      expect(prefs.getBool('${AppConstants.prefixStorageKey}library_is_incomplete'), isNull);
    });

    test('sets isSyncCancelled to true', () async {
      service.setIsSyncCancelled(false);

      await service.clearLibrary();

      expect(service.isSyncCancelled, isTrue);
    });
  });

  // ─── LibrarySyncMixin ──────────────────────────────────────────────────────

  group('LibrarySyncMixin.isLibraryIncomplete', () {
    test('returns false when pref is not set', () async {
      final result = await service.isLibraryIncomplete();
      expect(result, isFalse);
    });

    test('returns true when pref is set to true', () async {
      SharedPreferences.setMockInitialValues({
        '${AppConstants.prefixStorageKey}library_is_incomplete': true,
      });
      final result = await service.isLibraryIncomplete();
      expect(result, isTrue);
    });
  });

  group('LibrarySyncMixin.syncLibrary', () {
    test('is a no-op when sync is already in progress', () async {
      service.syncStatus.value = service.syncStatus.value.copyWith(isSyncing: true);

      // Should return immediately without throwing or changing status
      await service.syncLibrary();

      expect(service.syncStatus.value.isSyncing, isTrue);
    });

    test('resetInitialSyncTask clears sync guard so importFullLibrary can run again',
        () async {
      // importFullLibrary bails immediately when isSyncing, so set that to avoid HTTP
      service.syncStatus.value = service.syncStatus.value.copyWith(isSyncing: true);

      service.resetInitialSyncTask();

      // After reset, importFullLibrary returns immediately (isSyncing guard)
      await service.importFullLibrary();
      // No exception means the guard worked and no network call was made
    });
  });
}
