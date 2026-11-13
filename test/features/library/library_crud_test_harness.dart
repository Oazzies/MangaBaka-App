import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/auth_test_helpers.dart';

class LibraryCrudTestHarness {
  late AppDatabase db;
  late MemoryAuthStorage storage;
  late ProfileAuthService auth;
  late LibraryService service;
  late List<http.Request> requests;
  int refreshCalls = 0;

  final String entryUrl = '${LibraryConstants.baseUrl}/42';

  Future<void> setUp() async {
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
  }

  Future<void> tearDown() async {
    await db.close();
    SettingsManager.resetForTesting();
    await resetServiceLocator();
  }

  Future<T> withServer<T>(
    Future<http.Response> Function(http.Request request) handler,
    Future<T> Function() body,
  ) => http.runWithClient(
    body,
    () => MockClient((request) {
      requests.add(request);
      return handler(request);
    }),
  );

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
    await db
        .into(db.seriesTable)
        .insert(
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
    await db
        .into(db.libraryEntriesTable)
        .insert(
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
}
