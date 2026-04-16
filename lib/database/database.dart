import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bakahyou/database/tables.dart';
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/series/models/series.dart' as api;

part 'database.g.dart';

// New class to hold the result of our join query
class LibraryEntryWithSeries {
  final LibraryEntriesTableData libraryEntry;
  final SeriesTableData series;

  LibraryEntryWithSeries({
    required this.libraryEntry,
    required this.series,
  });
}

@DriftAccessor(tables: [SeriesTable])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  SeriesDao(AppDatabase db) : super(db);

  Future<void> upsertSeries(List<api.Series> series) async {
    await db.batch((batch) {
      batch.insertAll(
        db.seriesTable,
        series.map(
          (s) => SeriesTableCompanion.insert(
            id: s.id,
            state: Value(s.state),
            title: s.title,
            nativeTitle: Value(s.nativeTitle),
            romanizedTitle: Value(s.romanizedTitle),
            coverUrl: s.coverUrl,
            description: s.description,
            year: Value(s.year),
            status: Value(s.status),
            contentRating: Value(s.contentRating),
            type: Value(s.type),
            rating: Value(s.rating),
            finalVolume: Value(s.finalVolume),
            totalChapters: Value(s.totalChapters),
            lastUpdated: Value(s.lastUpdated),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}

@DriftAccessor(tables: [LibraryEntriesTable, SeriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  LibraryEntriesDao(AppDatabase db) : super(db);

  Future<void> upsertLibraryEntries(List<api.LibraryEntry> entries) async {
    await db.batch((batch) {
      batch.insertAll(
        db.libraryEntriesTable,
        entries.map(
          (e) => LibraryEntriesTableCompanion.insert(
            id: e.id,
            state: e.state,
            note: Value(e.note),
            progressChapter: Value(e.progressChapter),
            progressVolume: Value(e.progressVolume),
            numberOfRereads: Value(e.numberOfRereads),
            seriesId: e.series.id,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // New method to get all entries with series data
  Future<List<LibraryEntryWithSeries>> getAllEntriesWithSeries() {
    return (select(libraryEntriesTable))
        .join([
          innerJoin(
            seriesTable,
            seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
          ),
        ])
        .map((row) => LibraryEntryWithSeries(
              libraryEntry: row.readTable(libraryEntriesTable),
              series: row.readTable(seriesTable),
            ))
        .get();
  }
}

@DriftDatabase(
  tables: [SeriesTable, LibraryEntriesTable],
  daos: [SeriesDao, LibraryEntriesDao],
)
class AppDatabase extends _$AppDatabase {
  // Make the constructor private
  AppDatabase._() : super(_openConnection());

  // The single instance
  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}