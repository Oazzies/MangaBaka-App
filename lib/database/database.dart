import 'dart:convert';
import 'dart:io';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart' as exc;
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
  TextColumn get mergedWith => text().nullable()();
  TextColumn get title => text()();
  TextColumn get nativeTitle => text().nullable()();
  TextColumn get romanizedTitle => text().nullable()();
  TextColumn get secondaryTitles =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get coverUrl => text()();
  TextColumn get authors =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get artists =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get description => text()();
  TextColumn get year => text().nullable()();
  TextColumn get published => text().nullable()(); // JSON
  TextColumn get status => text().nullable()();
  TextColumn get isLicensed => text().nullable()();
  TextColumn get hasAnime => text().nullable()();
  TextColumn get anime => text().nullable()(); // JSON
  TextColumn get contentRating => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get finalVolume => text().nullable()();
  TextColumn get totalChapters => text().nullable()();
  TextColumn get links =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get publishers =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get genres =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get lastUpdated => text().nullable()();
  TextColumn get relationships => text().nullable()(); // JSON
  TextColumn get source => text().nullable()(); // JSON

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
  SeriesDao(super.db);

  // Gets the most recently updated series from the database.
  Future<SeriesTableData?> getLatestUpdatedSeries() async {
    try {
      return await (select(seriesTable)
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.lastUpdated,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();
    } catch (e) {
      _logger.severe('Failed to get latest updated series: $e');
      throw exc.DatabaseException(message: 'Failed to get latest updated series', originalError: e);
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
              mergedWith: Value(s.mergedWith),
              title: s.title,
              nativeTitle: Value(s.nativeTitle),
              romanizedTitle: Value(s.romanizedTitle),
              secondaryTitles: Value(json.encode(s.secondaryTitles)),
              coverUrl: s.coverUrl,
              authors: Value(json.encode(s.authors)),
              artists: Value(json.encode(s.artists)),
              description: s.description,
              year: Value(s.year),
              published: Value(
                s.published != null ? json.encode(s.published) : null,
              ),
              status: Value(s.status),
              isLicensed: Value(s.isLicensed),
              hasAnime: Value(s.hasAnime),
              anime: Value(s.anime != null ? json.encode(s.anime) : null),
              contentRating: Value(s.contentRating),
              type: Value(s.type),
              rating: Value(s.rating),
              finalVolume: Value(s.finalVolume),
              totalChapters: Value(s.totalChapters),
              links: Value(json.encode(s.links)),
              publishers: Value(json.encode(s.publishers)),
              genres: Value(json.encode(s.genres)),
              tags: Value(json.encode(s.tags)),
              lastUpdated: Value(s.lastUpdated),
              relationships: Value(
                s.relationships != null ? json.encode(s.relationships) : null,
              ),
              source: Value(s.source != null ? json.encode(s.source) : null),
            ),
          ),
          onConflict: DoUpdate(
            (old) => SeriesTableCompanion.custom(
              state: const CustomExpression<String>('excluded.state'),
              mergedWith: const CustomExpression<String>(
                'excluded.merged_with',
              ),
              title: const CustomExpression<String>('excluded.title'),
              nativeTitle: const CustomExpression<String>(
                'excluded.native_title',
              ),
              romanizedTitle: const CustomExpression<String>(
                'excluded.romanized_title',
              ),
              secondaryTitles: const CustomExpression<String>(
                'excluded.secondary_titles',
              ),
              coverUrl: const CustomExpression<String>('excluded.cover_url'),
              authors: const CustomExpression<String>('excluded.authors'),
              artists: const CustomExpression<String>('excluded.artists'),
              description: const CustomExpression<String>(
                'excluded.description',
              ),
              year: const CustomExpression<String>('excluded.year'),
              published: const CustomExpression<String>('excluded.published'),
              status: const CustomExpression<String>('excluded.status'),
              isLicensed: const CustomExpression<String>(
                'excluded.is_licensed',
              ),
              hasAnime: const CustomExpression<String>('excluded.has_anime'),
              anime: const CustomExpression<String>('excluded.anime'),
              contentRating: const CustomExpression<String>(
                'excluded.content_rating',
              ),
              type: const CustomExpression<String>('excluded.type'),
              rating: const CustomExpression<String>('excluded.rating'),
              finalVolume: const CustomExpression<String>(
                'excluded.final_volume',
              ),
              totalChapters: const CustomExpression<String>(
                'excluded.total_chapters',
              ),
              links: const CustomExpression<String>('excluded.links'),
              publishers: const CustomExpression<String>('excluded.publishers'),
              genres: const CustomExpression<String>('excluded.genres'),
              tags: const CustomExpression<String>('excluded.tags'),
              lastUpdated: const CustomExpression<String>(
                'excluded.last_updated',
              ),
              relationships: const CustomExpression<String>(
                'excluded.relationships',
              ),
              source: const CustomExpression<String>('excluded.source'),
            ),
          ),
        );
      });
    } catch (e) {
      _logger.severe('Failed to upsert series: $e');
      throw exc.DatabaseException(message: 'Failed to upsert series', originalError: e);
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
      throw exc.DatabaseException(message: 'Failed to insert library entry', originalError: e);
    }
  }

  Future<LibraryEntryWithSeries?> watchEntryWithSeries(String entryId) async {
    try {
      return await (select(db.libraryEntriesTable).join([
        innerJoin(
          db.seriesTable,
          db.seriesTable.id.equalsExp(db.libraryEntriesTable.seriesId),
        ),
      ])).getSingleOrNull().then(
        (result) => result != null
            ? LibraryEntryWithSeries(
                libraryEntry: result.readTable(db.libraryEntriesTable),
                series: result.readTable(db.seriesTable),
              )
            : null,
      );
    } catch (e) {
      _logger.severe('Failed to watch entry with series: $e');
      throw exc.DatabaseException(message: 'Failed to watch entry with series', originalError: e);
    }
  }
}

@DriftAccessor(tables: [LibraryEntriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  final _logger = LoggingService.logger;
  LibraryEntriesDao(super.db);

  Stream<LibraryEntryWithSeries?> watchEntryWithSeries(String seriesId) {
    try {
      final query = select(libraryEntriesTable).join([
        innerJoin(
          seriesTable,
          seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
        ),
      ])..where(libraryEntriesTable.seriesId.equals(seriesId));

      return query.watchSingleOrNull().map((row) {
        if (row == null) return null;
        return LibraryEntryWithSeries(
          libraryEntry: row.readTable(libraryEntriesTable),
          series: row.readTable(seriesTable),
        );
      });
    } catch (e) {
      _logger.severe('Failed to watch entry with series: $e');
      throw exc.DatabaseException(message: 'Failed to watch entry with series', originalError: e);
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
      throw exc.DatabaseException(message: 'Failed to watch all entries with series', originalError: e);
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
      throw exc.DatabaseException(message: 'Failed to upsert library entries', originalError: e);
    }
  }

  Future<void> updateEntryState(String seriesId, String newState) async {
    try {
      await (update(libraryEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .write(LibraryEntriesTableCompanion(state: Value(newState)));
    } catch (e) {
      _logger.severe('Failed to update entry state: $e');
      throw exc.DatabaseException(message: 'Failed to update entry state', originalError: e);
    }
  }

  Future<void> updateEntryRating(String seriesId, int newRating) async {
    try {
      await (update(libraryEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .write(LibraryEntriesTableCompanion(rating: Value(newRating)));
    } catch (e) {
      _logger.severe('Failed to update entry rating: $e');
      throw exc.DatabaseException(message: 'Failed to update entry rating', originalError: e);
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    try {
      await (delete(
        libraryEntriesTable,
      )..where((tbl) => tbl.seriesId.equals(seriesId))).go();
    } catch (e) {
      _logger.severe('Failed to delete entry: $e');
      throw exc.DatabaseException(message: 'Failed to delete entry', originalError: e);
    }
  }

  Future<void> deleteAllEntries() async {
    try {
      await delete(libraryEntriesTable).go();
    } catch (e) {
      _logger.severe('Failed to delete all entries: $e');
      throw exc.DatabaseException(message: 'Failed to delete all entries', originalError: e);
    }
  }
}

@DriftDatabase(
  tables: [SeriesTable, LibraryEntriesTable],
  daos: [SeriesDao, LibraryEntriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  static LazyDatabase _openConnection() {
    final logger = LoggingService.logger;
    return LazyDatabase(() async {
      try {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'manga_db.sqlite'));
        return NativeDatabase(file);
      } catch (e) {
        logger.severe('Failed to open database connection: $e');
        throw exc.DatabaseException(message: 'Failed to open database connection', originalError: e);
      }
    });
  }
}
