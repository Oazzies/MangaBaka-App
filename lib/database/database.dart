import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/series/models/series.dart' as api;

part 'database.g.dart';

// Table definitions
class SeriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text().nullable()();
  TextColumn get title => text()();
  TextColumn get nativeTitle => text().nullable()();
  TextColumn get romanizedTitle => text().nullable()();
  TextColumn get coverUrl => text()();
  TextColumn get description => text()();
  TextColumn get year => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get contentRating => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get finalVolume => text().nullable()();
  TextColumn get totalChapters => text().nullable()();
  TextColumn get lastUpdated => text().nullable()();
  TextColumn get genres => text().withDefault(const Constant('[]'))(); // JSON array of genres

  @override
  Set<Column> get primaryKey => {id};
}

class LibraryEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get state => text()();
  TextColumn get note => text().nullable()();
  IntColumn get progressChapter => integer().nullable()();
  IntColumn get progressVolume => integer().nullable()();
  IntColumn get numberOfRereads => integer().nullable()();
  TextColumn get seriesId => text().references(SeriesTable, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

// Class to hold the result of our join query
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

  // Gets the most recently updated series from the database.
  Future<SeriesTableData?> getLatestUpdatedSeries() {
    return (select(seriesTable)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastUpdated, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertSeries(List<api.Series> series) async {
    if (series.isEmpty) return;
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
            genres: Value(jsonEncode(s.genres)),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> insertLibraryEntry(
      String id, String state, String seriesId) async {
    await into(db.libraryEntriesTable).insert(
      LibraryEntriesTableCompanion.insert(
        id: id,
        state: state,
        seriesId: seriesId,
      ),
    );
  }

  Future<LibraryEntryWithSeries?> watchEntryWithSeries(String entryId) {
    return (select(db.libraryEntriesTable)
            .join([
              innerJoin(db.seriesTable,
                  db.seriesTable.id.equalsExp(db.libraryEntriesTable.seriesId))
            ]))
        .getSingleOrNull()
        .then(
          (result) => result != null
              ? LibraryEntryWithSeries(
                  libraryEntry: result.readTable(db.libraryEntriesTable),
                  series: result.readTable(db.seriesTable),
                )
              : null,
        );
  }
}

@DriftAccessor(tables: [LibraryEntriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  LibraryEntriesDao(AppDatabase db) : super(db);

  Stream<List<LibraryEntryWithSeries>> watchAllEntriesWithSeries() {
    return (select(db.libraryEntriesTable).join([
      innerJoin(db.seriesTable,
          db.seriesTable.id.equalsExp(db.libraryEntriesTable.seriesId))
    ])).watch().map((rows) {
      return rows.map((row) {
        return LibraryEntryWithSeries(
          libraryEntry: row.readTable(db.libraryEntriesTable),
          series: row.readTable(db.seriesTable),
        );
      }).toList();
    });
  }

  Future<void> upsertLibraryEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(
        db.libraryEntriesTable,
        entries.map((e) => LibraryEntriesTableCompanion.insert(
          id: e.id,
          state: e.state,
          note: Value(e.note),
          progressChapter: Value(e.progressChapter),
          progressVolume: Value(e.progressVolume),
          numberOfRereads: Value(e.numberOfRereads),
          seriesId: e.series.id,
        )),
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}

@DriftDatabase(tables: [SeriesTable, LibraryEntriesTable], daos: [
  SeriesDao,
  LibraryEntriesDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'manga_db.sqlite'));
      return NativeDatabase(file);
    });
  }
}