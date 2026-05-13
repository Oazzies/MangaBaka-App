import 'dart:convert';
import 'dart:io';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart' as exc;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;
import 'package:mangabaka_app/features/series/models/series.dart' as api;

import 'tables/series_table.dart';
import 'tables/library_entries_table.dart';

part 'database.g.dart';
part 'daos/series_dao.dart';
part 'daos/library_entries_dao.dart';

class LibraryEntryWithSeries {
  final LibraryEntriesTableData libraryEntry;
  final SeriesTableData series;

  LibraryEntryWithSeries({required this.libraryEntry, required this.series});
}

@DriftDatabase(
  tables: [SeriesTable, LibraryEntriesTable],
  daos: [SeriesDao, LibraryEntriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        // Robust "Self-Healing" Migration Strategy:
        // Instead of linear version checks, we verify the actual schema state.
        // This handles skip-upgrades (e.g. v1 -> v4) and potential inconsistencies.
        
        try {
          // 1. Check existing tables
          final tables = await customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
          final tableNames = tables.map((row) => row.read<String>('name')).toSet();

          // 2. Create tables ONLY if they don't exist
          if (!tableNames.contains('series_table')) {
            await m.createTable(seriesTable);
          }
          if (!tableNames.contains('library_entries_table')) {
            await m.createTable(libraryEntriesTable);
          }

          // 3. Inspect columns for existing tables
          final seriesColumns = await customSelect('PRAGMA table_info("series_table")').get();
          final seriesColumnNames = seriesColumns.map((row) => row.data['name'] as String).toSet();

          final libraryColumns = await customSelect('PRAGMA table_info("library_entries_table")').get();
          final libraryColumnNames = libraryColumns.map((row) => row.data['name'] as String).toSet();

          Future<void> addIfMissing(GeneratedColumn col, TableInfo table, Set<String> existing) async {
            if (!existing.contains(col.name)) {
              await m.addColumn(table, col);
              LoggingService.logger.info('Migration: Added column ${col.name} to ${table.actualTableName}.');
            }
          }

          // 4. Ensure all SeriesTable columns exist (id is primary key, created with table)
          await addIfMissing(seriesTable.state, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.mergedWith, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.title, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.nativeTitle, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.romanizedTitle, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.secondaryTitles, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.coverUrl, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.authors, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.artists, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.description, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.year, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.published, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.status, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.isLicensed, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.hasAnime, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.anime, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.contentRating, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.type, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.rating, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.finalVolume, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.totalChapters, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.links, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.publishers, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.genres, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.tags, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.lastUpdated, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.relationships, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.source, seriesTable, seriesColumnNames);

          // 5. Ensure all LibraryEntriesTable columns exist
          await addIfMissing(libraryEntriesTable.state, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.note, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.progressChapter, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.progressVolume, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.numberOfRereads, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.rating, libraryEntriesTable, libraryColumnNames);
          await addIfMissing(libraryEntriesTable.seriesId, libraryEntriesTable, libraryColumnNames);
        } catch (e, st) {
          LoggingService.logger.severe('Critical failure during database migration: $e\n$st');
          rethrow;
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  AppDatabase() : super(_openConnection());

  static LazyDatabase _openConnection() {
    final logger = LoggingService.logger;
    return LazyDatabase(() async {
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'manga_db.sqlite'));
        return NativeDatabase.createInBackground(file);
      } catch (e) {
        logger.severe('Failed to open database connection: $e');
        throw exc.DatabaseException(message: 'Failed to open database connection', originalError: e);
      }
    });
  }
}
