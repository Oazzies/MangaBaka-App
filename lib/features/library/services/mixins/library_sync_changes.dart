import 'package:logging/logging.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Applies one page of `/v2/my/library/changes` feed items into the local
/// Drift database. Returns the number of entries written, or `null` when
/// [isStale] becomes true mid-flight.
Future<int?> applyLibraryFeedChanges({
  required List<Map<String, dynamic>> items,
  required Set<String>? seen,
  required bool refreshSeries,
  required AppDatabase database,
  required Logger logger,
  required Future<List<Series>> Function(List<String> ids) fetchSeriesBatch,
  required bool Function() isStale,
}) async {
  final bySeries = <String, Map<String, dynamic>?>{};
  for (final item in items) {
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
    written = writable.length;
    if (seen != null) {
      seen.addAll(writable.map((e) => e['id'].toString()));
    }
  });
  return written;
}
