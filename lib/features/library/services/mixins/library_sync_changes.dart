import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Returns entries written, or null once [isStale] turns true mid-page.
Future<int?> applyLibraryFeedChanges({
  required List<Map<String, dynamic>> items,
  required Set<String>? seen,
  Set<int>? seenLists,
  required bool refreshSeries,
  required AppDatabase database,
  required Logger logger,
  required Future<List<Series>> Function(List<String> ids) fetchSeriesBatch,
  required bool Function() isStale,
}) async {
  final bySeries = <String, Map<String, dynamic>?>{};
  final lists = _LibraryListChanges();
  for (final item in items) {
    if (item['type'] == 'list') {
      lists.add(item);
      continue;
    }
    if (item['type'] != 'entry') continue;
    final current = item['current'];
    if (current is! Map) continue;
    final seriesId = current['series_id']?.toString();
    if (seriesId == null || seriesId.isEmpty) continue;
    switch (item['action']) {
      case 'upsert':
        bySeries[seriesId] = current.cast<String, dynamic>();
      case 'delete':
        bySeries[seriesId] = null;
    }
  }

  final upserts = [
    for (final e in bySeries.values)
      if (e != null) e,
  ];
  final deletes = [
    for (final e in bySeries.entries)
      if (e.value == null) e.key,
  ];

  final ids = [for (final e in upserts) e['series_id'].toString()];
  final stored = seen != null && !refreshSeries
      ? await database.seriesDao.existingIds(ids)
      : <String>{};
  final series = await fetchSeriesBatch([
    for (final id in ids)
      if (!stored.contains(id)) id,
  ]);
  if (isStale()) return null;

  var written = 0;
  await database.transaction(() async {
    await database.seriesDao.upsertSeries(series);
    final have = await database.seriesDao.existingIds(ids);
    final writable = [
      for (final e in upserts)
        if (have.contains(e['series_id'].toString())) e,
    ];
    if (writable.length != upserts.length) {
      logger.warning(
        'Skipped ${upserts.length - writable.length} entries whose series '
        'is not in the catalog.',
      );
    }
    await database.libraryEntriesDao.applyFeedChanges(
      upserts: writable,
      deletedSeriesIds: deletes,
    );
    await lists.apply(database.libraryListsDao, writable, deletes);
    seenLists?.addAll(lists.upserts.keys);
    written = writable.length;
    if (seen != null) {
      seen.addAll(writable.map((e) => e['id'].toString()));
    }
  });
  return written;
}

class _LibraryListChanges {
  final Map<int, LibraryListsTableCompanion> upserts = {};
  final Set<int> deletes = {};

  void add(Map<String, dynamic> item) {
    final current = item['current'];
    if (current is! Map) return;
    final id = _asInt(current['id']);
    if (id == null) return;
    switch (item['action']) {
      case 'upsert':
        final name = current['name']?.toString();
        if (name == null) return;
        deletes.remove(id);
        upserts[id] = LibraryListsTableCompanion(
          id: Value(id),
          name: Value(name),
          isPrivate: Value(current['is_private'] == true),
        );
      case 'delete':
        upserts.remove(id);
        deletes.add(id);
    }
  }

  Future<void> apply(
    LibraryListsDao dao,
    List<Map<String, dynamic>> entries,
    List<String> deletedSeriesIds,
  ) async {
    await dao.upsertLists(upserts.values.toList());
    await dao.deleteLists(deletes);
    await dao.removeSeries(deletedSeriesIds);
    await dao.setMemberships({
      for (final e in entries)
        if (e['list_ids'] is List)
          e['series_id'].toString(): {
            for (final raw in e['list_ids'] as List)
              if (_asInt(raw) case final int id) id,
          },
    });
  }

  static int? _asInt(Object? v) => switch (v) {
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };
}
