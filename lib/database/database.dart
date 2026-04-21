import 'dart:convert';
import 'dart:io';
import 'package:bakahyou/utils/services/logging_service.dart';
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
  TextColumn get genres =>
      text().withDefault(const Constant('[]'))(); // JSON array of genres

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
  IntColumn get rating => integer().nullable()();
  TextColumn get seriesId => text().references(SeriesTable, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

// Class to hold the result of our join query
class LibraryEntryWithSeries {
  final LibraryEntriesTableData libraryEntry;
  final SeriesTableData series;

  LibraryEntryWithSeries({required this.libraryEntry, required this.series});
}

@DriftAccessor(tables: [SeriesTable])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  final _logger = LoggingService.logger;
  SeriesDao(AppDatabase db) : super(db);

  // Gets the most recently updated series from the database.
  Future<SeriesTableData?> getLatestUpdatedSeries() async {
    try {
      return await (select(seriesTable)
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.lastUpdated,
                    mode: OrderingMode.desc,
                  )
            ])
            ..limit(1))
          .getSingleOrNull();
    } catch (e) {
      _logger.severe('Failed to get latest updated series: $e');
      throw Exception('Failed to get latest updated series.');
    }
  }

  Future<void> upsertSeries(List<api.Series> series) async {
    if (series.isEmpty) return;
    try {
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
              genres: Value(json.encode(s.genres)),
            ),
          ),
          onConflict: DoUpdate(
            (old) => SeriesTableCompanion.custom(
              state: const CustomExpression<String>('excluded.state'),
              title: const CustomExpression<String>('excluded.title'),
              nativeTitle:
                  const CustomExpression<String>('excluded.native_title'),
              romanizedTitle:
                  const CustomExpression<String>('excluded.romanized_title'),
              coverUrl: const CustomExpression<String>('excluded.cover_url'),
              description:
                  const CustomExpression<String>('excluded.description'),
              year: const CustomExpression<String>('excluded.year'),
              status: const CustomExpression<String>('excluded.status'),
              contentRating:
                  const CustomExpression<String>('excluded.content_rating'),
              type: const CustomExpression<String>('excluded.type'),
              rating: const CustomExpression<String>('excluded.rating'),
              finalVolume:
                  const CustomExpression<String>('excluded.final_volume'),
              totalChapters:
                  const CustomExpression<String>('excluded.total_chapters'),
              lastUpdated:
                  const CustomExpression<String>('excluded.last_updated'),
              genres: const CustomExpression<String>('excluded.genres'),
            ),
          ),
        );
      });
    } catch (e) {
      _logger.severe('Failed to upsert series: $e');
      throw Exception('Failed to upsert series.');
    }
  }

  Future<void> insertLibraryEntry(
    String id,
    String state,
    String seriesId,
  ) async {
    try {
      await into(db.libraryEntriesTable).insert(
        LibraryEntriesTableCompanion.insert(
          id: id,
          state: state,
          seriesId: seriesId,
        ),
      );
    } catch (e) {
      _logger.severe('Failed to insert library entry: $e');
      throw Exception('Failed to insert library entry.');
    }
  }

  Future<LibraryEntryWithSeries?> watchEntryWithSeries(String entryId) async {
    try {
      return await (select(db.libraryEntriesTable).join([
        innerJoin(
          db.seriesTable,
          db.seriesTable.id.equalsExp(db.libraryEntriesTable.seriesId),
        ),
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
    } catch (e) {
      _logger.severe('Failed to watch entry with series: $e');
      throw Exception('Failed to watch entry with series.');
    }
  }
}

@DriftAccessor(tables: [LibraryEntriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  final _logger = LoggingService.logger;
  LibraryEntriesDao(AppDatabase db) : super(db);

  Stream<LibraryEntryWithSeries?> watchEntryWithSeries(String seriesId) {
    try {
      final query = select(libraryEntriesTable).join([
        innerJoin(
          seriesTable,
          seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
        ),
      ])
        ..where(libraryEntriesTable.seriesId.equals(seriesId));

      return query.watchSingleOrNull().map((row) {
        if (row == null) return null;
        return LibraryEntryWithSeries(
          libraryEntry: row.readTable(libraryEntriesTable),
          series: row.readTable(seriesTable),
        );
      });
    } catch (e) {
      _logger.severe('Failed to watch entry with series: $e');
      throw Exception('Failed to watch entry with series.');
    }
  }

  Stream<List<LibraryEntryWithSeries>> watchAllEntriesWithSeries() {
    try {
      final query = select(libraryEntriesTable).join([
        innerJoin(
          seriesTable,
          seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
        ),
      ]);

      return query.watch().map((rows) {
        return rows
            .map(
              (row) => LibraryEntryWithSeries(
                libraryEntry: row.readTable(libraryEntriesTable),
                series: row.readTable(seriesTable),
              ),
            )
            .toList();
      });
    } catch (e) {
      _logger.severe('Failed to watch all entries with series: $e');
      throw Exception('Failed to watch all entries with series.');
    }
  }

  Future<void> upsertLibraryEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    try {
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
    } catch (e) {
      _logger.severe('Failed to upsert library entries: $e');
      throw Exception('Failed to upsert library entries.');
    }
  }

  Future<void> updateEntryState(String seriesId, String newState) async {
    try {
      await (update(libraryEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .write(LibraryEntriesTableCompanion(state: Value(newState)));
    } catch (e) {
      _logger.severe('Failed to update entry state: $e');
      throw Exception('Failed to update entry state.');
    }
  }

  Future<void> updateEntryRating(String seriesId, int newRating) async {
    try {
      await (update(libraryEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .write(LibraryEntriesTableCompanion(rating: Value(newRating)));
    } catch (e) {
      _logger.severe('Failed to update entry rating: $e');
      throw Exception('Failed to update entry rating.');
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    try {
      await (delete(libraryEntriesTable)
            ..where((tbl) => tbl.seriesId.equals(seriesId)))
          .go();
    } catch (e) {
      _logger.severe('Failed to delete entry: $e');
      throw Exception('Failed to delete entry.');
    }
  }
}

@DriftDatabase(
  tables: [SeriesTable, LibraryEntriesTable],
  daos: [SeriesDao, LibraryEntriesDao],
)
class AppDatabase extends _$AppDatabase {
  final _logger = LoggingService.logger;
  AppDatabase._() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  static LazyDatabase _openConnection() {
    final _logger = LoggingService.logger;
    return LazyDatabase(() async {
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'manga_db.sqlite'));
        return NativeDatabase(file);
      } catch (e) {
        _logger.severe('Failed to open database connection: $e');
        throw Exception('Failed to open database connection.');
      }
    });
  }
}
