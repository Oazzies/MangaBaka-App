import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;
  late StatisticsService service;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = StatisticsService(db);
  });

  tearDown(() async {
    await db.close();
    await resetServiceLocator();
  });

  group('StatisticsService', () {
    test('getTotalSeries returns 0 initially', () async {
      final total = await service.getTotalSeries();
      expect(total, 0);
    });

    test('getTotalSeries respects contentPreferences', () async {
      await db.into(db.seriesTable).insert(SeriesTableCompanion.insert(
        id: '1',
        title: 'SFW Series',
        coverUrl: '',
        description: '',
        status: const drift.Value(''),
        isLicensed: const drift.Value(''),
        hasAnime: const drift.Value(''),
        contentRating: const drift.Value('safe'),
        type: const drift.Value(''),
        lastUpdated: drift.Value(DateTime.now().toIso8601String()),
      ));
      await db.into(db.seriesTable).insert(SeriesTableCompanion.insert(
        id: '2',
        title: 'NSFW Series',
        coverUrl: '',
        description: '',
        status: const drift.Value(''),
        isLicensed: const drift.Value(''),
        hasAnime: const drift.Value(''),
        contentRating: const drift.Value('suggestive'),
        type: const drift.Value(''),
        lastUpdated: drift.Value(DateTime.now().toIso8601String()),
      ));

      await db.into(db.libraryEntriesTable).insert(LibraryEntriesTableCompanion.insert(
        id: 'e1',
        state: 'reading',
        seriesId: '1',
      ));
      await db.into(db.libraryEntriesTable).insert(LibraryEntriesTableCompanion.insert(
        id: 'e2',
        state: 'reading',
        seriesId: '2',
      ));

      expect(await service.getTotalSeries(), 2);
      expect(await service.getTotalSeries(contentPreferences: ['safe']), 1);
      expect(await service.getTotalSeries(contentPreferences: ['suggestive']), 1);
      expect(await service.getTotalSeries(contentPreferences: ['safe', 'suggestive']), 2);
    });

    test('getChaptersRead respects contentPreferences', () async {
      await db.into(db.seriesTable).insert(SeriesTableCompanion.insert(
        id: 's1',
        title: 'S1',
        coverUrl: '',
        description: '',
        status: const drift.Value(''),
        isLicensed: const drift.Value(''),
        hasAnime: const drift.Value(''),
        contentRating: const drift.Value('safe'),
        type: const drift.Value(''),
        lastUpdated: drift.Value(DateTime.now().toIso8601String()),
      ));
      await db.into(db.seriesTable).insert(SeriesTableCompanion.insert(
        id: 's2',
        title: 'S2',
        coverUrl: '',
        description: '',
        status: const drift.Value(''),
        isLicensed: const drift.Value(''),
        hasAnime: const drift.Value(''),
        contentRating: const drift.Value('suggestive'),
        type: const drift.Value(''),
        lastUpdated: drift.Value(DateTime.now().toIso8601String()),
      ));

      await db.into(db.libraryEntriesTable).insert(LibraryEntriesTableCompanion.insert(
        id: 'e1_prog',
        state: 'reading',
        seriesId: 's1',
        progressChapter: const drift.Value(10),
      ));
      await db.into(db.libraryEntriesTable).insert(LibraryEntriesTableCompanion.insert(
        id: 'e2_prog',
        state: 'reading',
        seriesId: 's2',
        progressChapter: const drift.Value(20),
      ));

      expect(await service.getChaptersRead(), 30);
      expect(await service.getChaptersRead(contentPreferences: ['safe']), 10);
    });
  });
}
