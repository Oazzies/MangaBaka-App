part of '../database.dart';

@DriftAccessor(tables: [LibraryEntriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  final _logger = LoggingService.logger;
  LibraryEntriesDao(super.db);

  Future<LibraryEntryWithSeries?> getEntryBySeriesId(String seriesId) async {
    try {
      final query = select(libraryEntriesTable).join([
        innerJoin(
          seriesTable,
          seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
        ),
      ])..where(libraryEntriesTable.seriesId.equals(seriesId));

      final row = await query.getSingleOrNull();
      if (row == null) return null;
      return LibraryEntryWithSeries(
        libraryEntry: row.readTable(libraryEntriesTable),
        series: row.readTable(seriesTable),
      );
    } catch (e) {
      _logger.severe('Failed to get entry by series ID: $e');
      throw exc.DatabaseException(message: 'Failed to get entry by series ID', originalError: e);
    }
  }

  /// The stored entry rows for [seriesIds], keyed by series id. Series rows
  /// are not joined: callers compare the entry fields only.
  Future<Map<String, LibraryEntriesTableData>> getEntriesBySeriesIds(
    Iterable<String> seriesIds,
  ) async {
    final ids = seriesIds.toList();
    if (ids.isEmpty) return {};
    try {
      final rows = await (select(libraryEntriesTable)
            ..where((t) => t.seriesId.isIn(ids)))
          .get();
      return {for (final r in rows) r.seriesId: r};
    } catch (e) {
      _logger.severe('Failed to get entries by series IDs: $e');
      throw exc.DatabaseException(message: 'Failed to get entries by series IDs', originalError: e);
    }
  }

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
      await db.transaction(() async {
        final uniqueSeriesIds =
            entries.map((e) => e.series.id).toSet().toList();

        // Delete any existing entries for these series to prevent duplicates
        await (delete(db.libraryEntriesTable)
              ..where((t) => t.seriesId.isIn(uniqueSeriesIds)))
            .go();

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
                rating: Value(e.rating),
                seriesId: e.series.id,
              ),
            ),
            mode: InsertMode.insertOrReplace,
          );
        });
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

  Future<void> updateEntryProgress(String seriesId, {int? progressChapter, int? progressVolume}) async {
    try {
      await (update(libraryEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .write(LibraryEntriesTableCompanion(
            progressChapter: progressChapter != null ? Value(progressChapter) : const Value.absent(),
            progressVolume: progressVolume != null ? Value(progressVolume) : const Value.absent(),
          ));
    } catch (e) {
      _logger.severe('Failed to update entry progress: $e');
      throw exc.DatabaseException(message: 'Failed to update entry progress', originalError: e);
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

  Future<void> deleteEntriesNotIn(List<String> validIds) async {
    try {
      final validSet = validIds.toSet();
      // Only select IDs to save memory
      final query = selectOnly(libraryEntriesTable)..addColumns([libraryEntriesTable.id]);
      final allIds = await query.map((row) => row.read(libraryEntriesTable.id)!).get();
      
      final toDelete = allIds
          .where((id) => !validSet.contains(id))
          .toList();

      if (toDelete.isEmpty) return;

      await db.transaction(() async {
        for (var i = 0; i < toDelete.length; i += 500) {
          final end = (i + 500 > toDelete.length) ? toDelete.length : i + 500;
          final chunk = toDelete.sublist(i, end);
          await (delete(libraryEntriesTable)..where((t) => t.id.isIn(chunk)))
              .go();
        }
      });
    } catch (e) {
      _logger.severe('Failed to delete stale entries: $e');
      throw exc.DatabaseException(
          message: 'Failed to delete stale entries', originalError: e);
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
