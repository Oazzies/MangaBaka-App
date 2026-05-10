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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          final seriesColumns = await customSelect('PRAGMA table_info("series_table")').get();
          final seriesColumnNames = seriesColumns.map((row) => row.data['name'] as String).toSet();

          final libraryColumns = await customSelect('PRAGMA table_info("library_entries_table")').get();
          final libraryColumnNames = libraryColumns.map((row) => row.data['name'] as String).toSet();

          Future<void> addIfMissing(GeneratedColumn col, TableInfo table, Set<String> existing) async {
            if (!existing.contains(col.name)) {
              await m.addColumn(table, col);
            } else {
              LoggingService.logger.info('Migration: Column ${col.name} already exists in ${table.actualTableName}, skipping.');
            }
          }

          await addIfMissing(seriesTable.mergedWith, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.contentRating, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.type, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.rating, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.finalVolume, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.totalChapters, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.lastUpdated, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.relationships, seriesTable, seriesColumnNames);
          await addIfMissing(seriesTable.source, seriesTable, seriesColumnNames);
          
          await addIfMissing(libraryEntriesTable.rating, libraryEntriesTable, libraryColumnNames);
        }
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
