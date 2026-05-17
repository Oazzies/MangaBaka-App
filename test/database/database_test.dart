import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:get_it/get_it.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    if (!GetIt.I.isRegistered<LoggingService>()) {
      GetIt.I.registerSingleton<LoggingService>(LoggingService());
    }

    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('initializes with correct schema version', () async {
      expect(db.schemaVersion, 3);
    });

    test('can insert and retrieve a series via custom query', () async {
      // Using custom query to avoid complex api.Series object for basic DAO test
      await db
          .into(db.seriesTable)
          .insert(
            SeriesTableCompanion.insert(
              id: '1',
              title: 'Test Manga',
              state: const Value('reading'),
              coverUrl: 'https://example.com/cover.jpg',
              description: 'A test description',
              lastUpdated: Value(DateTime.now().toIso8601String()),
            ),
          );

      final retrieved = await (db.select(
        db.seriesTable,
      )..where((t) => t.id.equals('1'))).getSingleOrNull();
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Manga');
    });

    test('can insert and retrieve a library entry', () async {
      await db
          .into(db.seriesTable)
          .insert(
            SeriesTableCompanion.insert(
              id: '1',
              title: 'Test Manga',
              state: const Value('reading'),
              coverUrl: 'https://example.com/cover.jpg',
              description: 'A test description',
              lastUpdated: Value(DateTime.now().toIso8601String()),
            ),
          );

      await db
          .into(db.libraryEntriesTable)
          .insert(
            LibraryEntriesTableCompanion.insert(
              id: 'entry_1',
              seriesId: '1',
              state: 'plan_to_read',
              progressChapter: const Value(1),
              progressVolume: const Value(0),
            ),
          );

      final retrieved = await (db.select(
        db.libraryEntriesTable,
      )..where((t) => t.seriesId.equals('1'))).getSingleOrNull();
      expect(retrieved, isNotNull);
      expect(retrieved!.state, 'plan_to_read');
    });

    test('self-healing migration ensures tables and indices exist', () async {
      final tableNames = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final names = tableNames.map((row) => row.read<String>('name')).toList();

      expect(names, contains('series_table'));
      expect(names, contains('library_entries_table'));

      final indexNames = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
          .get();
      final indices = indexNames
          .map((row) => row.read<String>('name'))
          .toList();
      expect(indices, contains('series_title_idx'));
      expect(indices, contains('library_series_idx'));
      expect(indices, contains('library_state_idx'));
    });

    test(
      'robust migration preserves data and adds missing columns/indices when upgrading from v1',
      () async {
        final rawDb = sqlite3.openInMemory();

        // Create v1 schema
        rawDb.execute('''
        CREATE TABLE series_table (
          id TEXT PRIMARY KEY,
          title TEXT,
          cover_url TEXT,
          description TEXT
        );
      ''');
        rawDb.execute('''
        CREATE TABLE library_entries_table (
          id TEXT PRIMARY KEY,
          series_id TEXT,
          state TEXT
        );
      ''');

        // Insert mock data
        rawDb.execute('''
        INSERT INTO series_table (id, title, cover_url, description)
        VALUES ('1', 'Series 1', 'https://example.com/1.jpg', 'Desc 1');
      ''');
        rawDb.execute('''
        INSERT INTO library_entries_table (id, series_id, state)
        VALUES ('entry_1', '1', 'reading');
      ''');

        // Set user_version to 1 to simulate a v1 database
        rawDb.execute('PRAGMA user_version = 1;');

        // Wrap it in Drift NativeDatabase
        final upgradeDb = AppDatabase.forTesting(NativeDatabase.opened(rawDb));

        // Verify schema version is 3
        expect(upgradeDb.schemaVersion, 3);

        // Let's verify our v1 data is still there!
        final retrievedSeries = await (upgradeDb.select(
          upgradeDb.seriesTable,
        )..where((t) => t.id.equals('1'))).getSingle();
        expect(retrievedSeries.title, 'Series 1');
        expect(retrievedSeries.coverUrl, 'https://example.com/1.jpg');
        expect(retrievedSeries.description, 'Desc 1');

        // Verify new columns exist and have correct defaults/nullability
        expect(retrievedSeries.mergedWith, isNull);
        expect(retrievedSeries.secondaryTitles, '[]'); // default value

        final retrievedEntry = await (upgradeDb.select(
          upgradeDb.libraryEntriesTable,
        )..where((t) => t.id.equals('entry_1'))).getSingle();
        expect(retrievedEntry.state, 'reading');
        expect(
          retrievedEntry.progressChapter,
          isNull,
        ); // newly added column, should be null

        // Verify indices were created
        final indexNames = await upgradeDb
            .customSelect("SELECT name FROM sqlite_master WHERE type='index'")
            .get();
        final indices = indexNames
            .map((row) => row.read<String>('name'))
            .toList();
        expect(indices, contains('series_title_idx'));
        expect(indices, contains('library_series_idx'));
        expect(indices, contains('library_state_idx'));

        await upgradeDb.close();
      },
    );
  });
}
