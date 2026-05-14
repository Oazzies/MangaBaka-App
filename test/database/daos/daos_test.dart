import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:get_it/get_it.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;

void main() {
  late AppDatabase db;

  api.Series createDummySeries(String id, String title) {
    return api.Series(
      id: id,
      state: 'published',
      title: title,
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: [],
      coverUrl: 'https://example.com/cover.jpg',
      rawCoverUrl: 'https://example.com/cover.jpg',
      authors: [],
      artists: [],
      description: 'Test description',
      year: '2024',
      status: 'ongoing',
      isLicensed: 'false',
      hasAnime: 'false',
      contentRating: 'safe',
      type: 'manga',
      rating: '0',
      finalVolume: '0',
      totalChapters: '0',
      links: [],
      publishers: [],
      genres: [],
      tags: [],
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  ft.setUp(() {
    if (!GetIt.I.isRegistered<LoggingService>()) {
      GetIt.I.registerSingleton<LoggingService>(LoggingService());
    }
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  ft.tearDown(() async {
    await db.close();
  });

  ft.group('SeriesDao', () {
    ft.test('upsertSeries and getLatestUpdatedSeries', () async {
      final series = createDummySeries('series_1', 'Manga One');

      await db.seriesDao.upsertSeries([series]);

      final latest = await db.seriesDao.getLatestUpdatedSeries();
      ft.expect(latest, ft.isNotNull);
      ft.expect(latest!.id, 'series_1');
      ft.expect(latest.title, 'Manga One');
    });
  });

  ft.group('LibraryEntriesDao', () {
    ft.test('upsertLibraryEntries and watchEntryWithSeries', () async {
      // Must have series first for foreign key
      await db.into(db.seriesTable).insert(
        SeriesTableCompanion.insert(
          id: 's1',
          title: 'Series One',
          coverUrl: 'url',
          description: 'desc',
        ),
      );

      final entry = api.LibraryEntry(
        id: 'e1',
        state: 'reading',
        series: createDummySeries('s1', 'Series One'),
      );

      await db.libraryEntriesDao.upsertLibraryEntries([entry]);

      final result = await db.libraryEntriesDao.watchEntryWithSeries('s1').first;
      ft.expect(result, ft.isNotNull);
      ft.expect(result!.libraryEntry.id, 'e1');
      ft.expect(result.series.id, 's1');
    });

    ft.test('updateEntryState updates correct entry', () async {
      await db.into(db.seriesTable).insert(
        SeriesTableCompanion.insert(
          id: 's1',
          title: 'Series One',
          coverUrl: 'url',
          description: 'desc',
        ),
      );
      await db.into(db.libraryEntriesTable).insert(
        LibraryEntriesTableCompanion.insert(
          id: 'e1',
          seriesId: 's1',
          state: 'reading',
        ),
      );

      await db.libraryEntriesDao.updateEntryState('s1', 'completed');
      
      final entry = await (db.select(db.libraryEntriesTable)..where((t) => t.seriesId.equals('s1'))).getSingle();
      ft.expect(entry.state, 'completed');
    });

    ft.test('deleteEntry removes entry', () async {
      await db.into(db.seriesTable).insert(
        SeriesTableCompanion.insert(
          id: 's1',
          title: 'Series One',
          coverUrl: 'url',
          description: 'desc',
        ),
      );
      await db.into(db.libraryEntriesTable).insert(
        LibraryEntriesTableCompanion.insert(
          id: 'e1',
          seriesId: 's1',
          state: 'reading',
        ),
      );

      await db.libraryEntriesDao.deleteEntry('s1');
      
      final entry = await (db.select(db.libraryEntriesTable)..where((t) => t.seriesId.equals('s1'))).getSingleOrNull();
      ft.expect(entry, ft.isNull);
    });
  });
}
