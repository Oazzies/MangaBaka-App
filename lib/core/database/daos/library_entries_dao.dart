part of '../database.dart';

@DriftAccessor(tables: [LibraryEntriesTable])
class LibraryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryEntriesDaoMixin {
  final _logger = LoggingService.logger;
  LibraryEntriesDao(super.db);

  Future<T> _guard<T>(String message, Future<T> Function() run) async {
    try {
      return await run();
    } catch (e, st) {
      _logger.severe(message, e, st);
      throw exc.DatabaseException(
        message: message,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Stream<T> _guardStream<T>(String message, Stream<T> Function() run) {
    try {
      return run();
    } catch (e, st) {
      _logger.severe(message, e, st);
      throw exc.DatabaseException(
        message: message,
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Which of [seriesIds] are in the library, with their covers.
  Future<Map<String, String>> libraryCoversFor(
    Iterable<String> seriesIds,
  ) => _guard('Failed to look up library series', () async {
    final ids = seriesIds.toSet().toList();
    final covers = <String, String>{};
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(
        i,
        i + 500 > ids.length ? ids.length : i + 500,
      );
      final query =
          selectOnly(libraryEntriesTable).join([
              innerJoin(
                seriesTable,
                seriesTable.id.equalsExp(libraryEntriesTable.seriesId),
              ),
            ])
            ..addColumns([seriesTable.id, seriesTable.coverUrl])
            ..where(libraryEntriesTable.seriesId.isIn(chunk));
      for (final row in await query.get()) {
        covers[row.read(seriesTable.id)!] = row.read(seriesTable.coverUrl)!;
      }
    }
    return covers;
  });

  Future<LibraryEntryWithSeries?> getEntryBySeriesId(String seriesId) =>
      _guard('Failed to get entry by series ID', () async {
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
      });

  Future<Map<String, LibraryEntriesTableData>> getEntriesBySeriesIds(
    Iterable<String> seriesIds,
  ) {
    final ids = seriesIds.toList();
    if (ids.isEmpty) return Future.value({});
    return _guard('Failed to get entries by series IDs', () async {
      final rows = await (select(
        libraryEntriesTable,
      )..where((t) => t.seriesId.isIn(ids))).get();
      return {for (final r in rows) r.seriesId: r};
    });
  }

  Stream<LibraryEntryWithSeries?> watchEntryWithSeries(String seriesId) =>
      _guardStream('Failed to watch entry with series', () {
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
      });

  Stream<List<LibraryEntryWithSeries>> watchAllEntriesWithSeries() =>
      _guardStream('Failed to watch all entries with series', () {
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
      });

  Future<void> upsertLibraryEntries(List<api.LibraryEntry> entries) {
    if (entries.isEmpty) return Future.value();
    return _guard('Failed to upsert library entries', () async {
      await db.transaction(() async {
        final uniqueSeriesIds = entries
            .map((e) => e.series.id)
            .toSet()
            .toList();

        await (delete(
          db.libraryEntriesTable,
        )..where((t) => t.seriesId.isIn(uniqueSeriesIds))).go();

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
    });
  }

  Future<void> applyFeedChanges({
    required List<Map<String, dynamic>> upserts,
    required List<String> deletedSeriesIds,
  }) {
    if (upserts.isEmpty && deletedSeriesIds.isEmpty) return Future.value();
    int? asInt(Object? v) => switch (v) {
      final num n => n.toInt(),
      final String s => num.tryParse(s)?.toInt(),
      _ => null,
    };
    return _guard('Failed to apply library changes', () async {
      await db.transaction(() async {
        final replaced = [
          ...deletedSeriesIds,
          for (final e in upserts) e['series_id'].toString(),
        ];
        for (var i = 0; i < replaced.length; i += 500) {
          final chunk = replaced.sublist(
            i,
            i + 500 > replaced.length ? replaced.length : i + 500,
          );
          await (delete(
            db.libraryEntriesTable,
          )..where((t) => t.seriesId.isIn(chunk))).go();
        }
        await db.batch((batch) {
          batch.insertAll(db.libraryEntriesTable, [
            for (final e in upserts)
              LibraryEntriesTableCompanion.insert(
                id: e['id'].toString(),
                state: e['state']?.toString() ?? '',
                note: Value(e['note']?.toString()),
                progressChapter: Value(asInt(e['progress_chapter'])),
                progressVolume: Value(asInt(e['progress_volume'])),
                numberOfRereads: Value(asInt(e['number_of_rereads'])),
                rating: Value(asInt(e['rating'])),
                seriesId: e['series_id'].toString(),
              ),
          ], mode: InsertMode.insertOrReplace);
        });
      });
    });
  }

  Future<void> updateEntryState(
    String seriesId,
    String newState, {
    int? progressChapter,
    int? progressVolume,
  }) => _guard('Failed to update entry state', () async {
    await (update(
      libraryEntriesTable,
    )..where((t) => t.seriesId.equals(seriesId))).write(
      LibraryEntriesTableCompanion(
        state: Value(newState),
        progressChapter: progressChapter != null
            ? Value(progressChapter)
            : const Value.absent(),
        progressVolume: progressVolume != null
            ? Value(progressVolume)
            : const Value.absent(),
      ),
    );
  });

  Future<void> updateEntryRating(String seriesId, int newRating) =>
      _guard('Failed to update entry rating', () async {
        await (update(libraryEntriesTable)
              ..where((t) => t.seriesId.equals(seriesId)))
            .write(LibraryEntriesTableCompanion(rating: Value(newRating)));
      });

  Future<void> updateEntryNote(String seriesId, String? newNote) =>
      _guard('Failed to update entry note', () async {
        await (update(libraryEntriesTable)
              ..where((t) => t.seriesId.equals(seriesId)))
            .write(LibraryEntriesTableCompanion(note: Value(newNote)));
      });

  Future<void> updateEntryProgress(
    String seriesId, {
    int? progressChapter,
    int? progressVolume,
  }) => _guard('Failed to update entry progress', () async {
    await (update(
      libraryEntriesTable,
    )..where((t) => t.seriesId.equals(seriesId))).write(
      LibraryEntriesTableCompanion(
        progressChapter: progressChapter != null
            ? Value(progressChapter)
            : const Value.absent(),
        progressVolume: progressVolume != null
            ? Value(progressVolume)
            : const Value.absent(),
      ),
    );
  });

  Future<void> deleteEntry(String seriesId) =>
      _guard('Failed to delete entry', () async {
        await (delete(
          libraryEntriesTable,
        )..where((tbl) => tbl.seriesId.equals(seriesId))).go();
      });

  Future<void> deleteEntriesNotIn(List<String> validIds) =>
      _guard('Failed to delete stale entries', () async {
        final validSet = validIds.toSet();
        final query = selectOnly(libraryEntriesTable)
          ..addColumns([libraryEntriesTable.id]);
        final allIds = await query
            .map((row) => row.read(libraryEntriesTable.id)!)
            .get();

        final toDelete = allIds.where((id) => !validSet.contains(id)).toList();
        if (toDelete.isEmpty) return;

        await db.transaction(() async {
          for (var i = 0; i < toDelete.length; i += 500) {
            final end = (i + 500 > toDelete.length)
                ? toDelete.length
                : i + 500;
            final chunk = toDelete.sublist(i, end);
            await (delete(
              libraryEntriesTable,
            )..where((t) => t.id.isIn(chunk))).go();
          }
        });
      });

  Future<void> deleteAllEntries() =>
      _guard('Failed to delete all entries', () async {
        await delete(libraryEntriesTable).go();
      });
}
