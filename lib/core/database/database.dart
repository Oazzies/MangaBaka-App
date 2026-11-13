import 'dart:convert';
import 'dart:io';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart' as exc;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mangabaka_app/features/library/models/library_entry.dart'
    as api;
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
      onCreate: (m) async {
        await m.createAll();
        // Create custom indices since Drift doesn't automatically detect the custom indexes getter in tables
        await m.createIndex(
          Index(
            'series_title_idx',
            'CREATE INDEX IF NOT EXISTS series_title_idx ON series_table (title)',
          ),
        );
        await m.createIndex(
          Index(
            'library_series_idx',
            'CREATE INDEX IF NOT EXISTS library_series_idx ON library_entries_table (series_id)',
          ),
        );
        await m.createIndex(
          Index(
            'library_state_idx',
            'CREATE INDEX IF NOT EXISTS library_state_idx ON library_entries_table (state)',
          ),
        );
      },
      onUpgrade: (m, from, to) async {
        // Robust "Self-Healing" Migration Strategy:
        // Instead of linear version checks, we verify the actual schema state.
        // This handles skip-upgrades (e.g. v1 -> v4) and potential inconsistencies.

        try {
          // 1. Check existing tables
          final tables = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table'",
          ).get();
          final tableNames = tables
              .map((row) => row.read<String>('name'))
              .toSet();

          // 2. Create tables ONLY if they don't exist
          if (!tableNames.contains('series_table')) {
            await m.createTable(seriesTable);
          }
          if (!tableNames.contains('library_entries_table')) {
            await m.createTable(libraryEntriesTable);
          }

          // 2.5. Create indices
          await m.createIndex(
            Index(
              'series_title_idx',
              'CREATE INDEX IF NOT EXISTS series_title_idx ON series_table (title)',
            ),
          );
          await m.createIndex(
            Index(
              'library_series_idx',
              'CREATE INDEX IF NOT EXISTS library_series_idx ON library_entries_table (series_id)',
            ),
          );
          await m.createIndex(
            Index(
              'library_state_idx',
              'CREATE INDEX IF NOT EXISTS library_state_idx ON library_entries_table (state)',
            ),
          );

          // 3. Inspect columns for existing tables
          final seriesColumns = await customSelect(
            'PRAGMA table_info("series_table")',
          ).get();
          final seriesColumnNames = seriesColumns
              .map((row) => row.data['name'] as String)
              .toSet();

          final libraryColumns = await customSelect(
            'PRAGMA table_info("library_entries_table")',
          ).get();
          final libraryColumnNames = libraryColumns
              .map((row) => row.data['name'] as String)
              .toSet();

          Future<void> addIfMissing(
            GeneratedColumn col,
            TableInfo table,
            Set<String> existing,
          ) async {
            if (!existing.contains(col.name)) {
              await m.addColumn(table, col);
              LoggingService.logger.info(
                'Migration: Added column ${col.name} to ${table.actualTableName}.',
              );
            }
          }

          for (final col in <GeneratedColumn>[
            seriesTable.state,
            seriesTable.mergedWith,
            seriesTable.title,
            seriesTable.nativeTitle,
            seriesTable.romanizedTitle,
            seriesTable.secondaryTitles,
            seriesTable.coverUrl,
            seriesTable.authors,
            seriesTable.artists,
            seriesTable.description,
            seriesTable.year,
            seriesTable.published,
            seriesTable.status,
            seriesTable.isLicensed,
            seriesTable.hasAnime,
            seriesTable.anime,
            seriesTable.contentRating,
            seriesTable.type,
            seriesTable.rating,
            seriesTable.finalVolume,
            seriesTable.totalChapters,
            seriesTable.links,
            seriesTable.publishers,
            seriesTable.genres,
            seriesTable.tags,
            seriesTable.lastUpdated,
            seriesTable.relationships,
            seriesTable.source,
          ]) {
            await addIfMissing(col, seriesTable, seriesColumnNames);
          }

          for (final col in <GeneratedColumn>[
            libraryEntriesTable.state,
            libraryEntriesTable.note,
            libraryEntriesTable.progressChapter,
            libraryEntriesTable.progressVolume,
            libraryEntriesTable.numberOfRereads,
            libraryEntriesTable.rating,
            libraryEntriesTable.seriesId,
          ]) {
            await addIfMissing(col, libraryEntriesTable, libraryColumnNames);
          }
        } catch (e, st) {
          LoggingService.logger.severe(
            'Critical failure during database migration',
            e,
            st,
          );
          rethrow;
        }
      },
      beforeOpen: (details) async {
        // WAL mode is enabled in NativeDatabase.createInBackground by default usually,
        // but we ensure PRAGMAs are set correctly here.
        await customStatement('PRAGMA foreign_keys = ON');
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA synchronous = NORMAL');
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
      } catch (e, st) {
        logger.severe('Failed to open database connection', e, st);
        throw exc.DatabaseException(
          message: 'Failed to open database connection',
          originalError: e,
          stackTrace: st,
        );
      }
    });
  }
}
