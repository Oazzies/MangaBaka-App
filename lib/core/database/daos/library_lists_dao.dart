part of '../database.dart';

@DriftAccessor(
  tables: [LibraryListsTable, LibraryListEntriesTable, LibraryEntriesTable],
)
class LibraryListsDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryListsDaoMixin {
  final _logger = LoggingService.logger;
  LibraryListsDao(super.db);

  static const int _chunk = 500;

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

  Iterable<List<T>> _chunks<T>(List<T> items) sync* {
    for (var i = 0; i < items.length; i += _chunk) {
      yield items.sublist(
        i,
        i + _chunk > items.length ? items.length : i + _chunk,
      );
    }
  }

  Stream<List<LibraryListsTableData>> watchLists() =>
      select(libraryListsTable).watch();

  Future<List<LibraryListsTableData>> getLists() =>
      _guard('Failed to read lists', () => select(libraryListsTable).get());

  Stream<List<LibraryListEntriesTableData>> watchMemberships() =>
      select(libraryListEntriesTable).watch();

  Stream<Set<int>> watchListIdsForSeries(String seriesId) =>
      (select(libraryListEntriesTable)
            ..where((t) => t.seriesId.equals(seriesId)))
          .watch()
          .map((rows) => {for (final r in rows) r.listId});

  /// Absent companion fields keep their stored value, so a feed upsert leaves createdAt alone.
  Future<void> upsertLists(List<LibraryListsTableCompanion> lists) {
    if (lists.isEmpty) return Future.value();
    return _guard('Failed to save lists', () async {
      await batch((b) {
        for (final list in lists) {
          b.insert(libraryListsTable, list, onConflict: DoUpdate((_) => list));
        }
      });
    });
  }

  Future<void> replaceAllLists(List<LibraryListsTableCompanion> lists) =>
      _guard('Failed to replace lists', () async {
        await transaction(() async {
          await pruneListsNotIn({for (final l in lists) l.id.value});
          await upsertLists(lists);
        });
      });

  Future<void> deleteLists(Iterable<int> ids) {
    final all = ids.toSet().toList();
    if (all.isEmpty) return Future.value();
    return _guard('Failed to delete lists', () async {
      await transaction(() async {
        for (final chunk in _chunks(all)) {
          await (delete(
            libraryListEntriesTable,
          )..where((t) => t.listId.isIn(chunk))).go();
          await (delete(
            libraryListsTable,
          )..where((t) => t.id.isIn(chunk))).go();
        }
      });
    });
  }

  Future<void> setPrivacy(Iterable<int> ids, {required bool isPrivate}) {
    final all = ids.toSet().toList();
    if (all.isEmpty) return Future.value();
    return _guard('Failed to update list privacy', () async {
      for (final chunk in _chunks(all)) {
        await (update(libraryListsTable)..where((t) => t.id.isIn(chunk))).write(
          LibraryListsTableCompanion(isPrivate: Value(isPrivate)),
        );
      }
    });
  }

  Future<void> pruneListsNotIn(Set<int> keep) =>
      _guard('Failed to prune lists', () async {
        final stored =
            await (selectOnly(libraryListsTable)
                  ..addColumns([libraryListsTable.id]))
                .map((r) => r.read(libraryListsTable.id)!)
                .get();
        await deleteLists(stored.where((id) => !keep.contains(id)));
      });

  /// Replaces each named series' memberships; a series mapped to an empty set leaves every list.
  Future<void> setMemberships(Map<String, Set<int>> listsBySeries) {
    if (listsBySeries.isEmpty) return Future.value();
    return _guard('Failed to save list memberships', () async {
      await transaction(() async {
        for (final chunk in _chunks(listsBySeries.keys.toList())) {
          await (delete(
            libraryListEntriesTable,
          )..where((t) => t.seriesId.isIn(chunk))).go();
        }
        await batch((b) {
          b.insertAll(libraryListEntriesTable, [
            for (final e in listsBySeries.entries)
              for (final listId in e.value)
                LibraryListEntriesTableCompanion.insert(
                  listId: listId,
                  seriesId: e.key,
                ),
          ], mode: InsertMode.insertOrIgnore);
        });
      });
    });
  }

  Future<void> removeSeries(Iterable<String> seriesIds) {
    final all = seriesIds.toSet().toList();
    if (all.isEmpty) return Future.value();
    return _guard('Failed to remove list memberships', () async {
      for (final chunk in _chunks(all)) {
        await (delete(
          libraryListEntriesTable,
        )..where((t) => t.seriesId.isIn(chunk))).go();
      }
    });
  }

  Future<void> pruneMembershipsWithoutEntry() =>
      _guard('Failed to prune list memberships', () async {
        await customUpdate(
          'DELETE FROM library_list_entries_table WHERE series_id NOT IN '
          '(SELECT series_id FROM library_entries_table)',
          updates: {libraryListEntriesTable},
          updateKind: UpdateKind.delete,
        );
      });

  Future<void> clearAll() => _guard('Failed to clear lists', () async {
    await transaction(() async {
      await delete(libraryListEntriesTable).go();
      await delete(libraryListsTable).go();
    });
  });
}
