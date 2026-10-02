import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/services/statistics_service.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
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

    test('getTopPublishers counts library series per publisher', () async {
      Future<void> add(String id, String publishers, String rating) async {
        await db.into(db.seriesTable).insert(SeriesTableCompanion.insert(
          id: id,
          title: 'S$id',
          coverUrl: '',
          description: '',
          status: const drift.Value(''),
          isLicensed: const drift.Value(''),
          hasAnime: const drift.Value(''),
          contentRating: drift.Value(rating),
          type: const drift.Value(''),
          publishers: drift.Value(publishers),
          lastUpdated: drift.Value(DateTime.now().toIso8601String()),
        ));
        await db.into(db.libraryEntriesTable).insert(
          LibraryEntriesTableCompanion.insert(
            id: 'e$id',
            state: 'reading',
            seriesId: id,
          ),
        );
      }

      await add('1', '["Shueisha","Viz Media"]', 'safe');
      await add('2', '["Shueisha"]', 'safe');
      // The same publisher twice on one series counts once.
      await add('3', '["Viz Media","Viz Media"]', 'safe');
      await add('4', '["Kodansha"]', 'erotica');
      await add('5', 'not json', 'safe');
      await add('6', '[]', 'safe');

      final all = await service.getTopPublishers();
      expect(all.map((p) => (p.name, p.count)).toList(), [
        ('Shueisha', 2),
        ('Viz Media', 2),
        ('Kodansha', 1),
      ]);

      final filtered = await service.getTopPublishers(
        contentPreferences: ['safe'],
        limit: 1,
      );
      expect(filtered.map((p) => p.name).toList(), ['Shueisha']);
    });
  });
}
