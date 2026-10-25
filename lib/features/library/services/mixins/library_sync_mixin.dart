import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';

const String _lastSyncKey = AppConstants.lastSyncKey;
const String _cursorKey = AppConstants.libraryCursorKey;
const String _isIncompleteKey =
    '${AppConstants.prefixStorageKey}library_is_incomplete';

mixin LibrarySyncMixin on LibraryServiceBase {
  bool _hasPerformedInitialSync = false;
  Future<void>? _initialSyncTask;

  /// Bumped whenever a running sync is invalidated (cancel, library clear,
  /// logout) and whenever a new sync starts. A sync loop compares the value
  /// it started with after every await: the boolean cancel flag alone is not
  /// enough, because the next sync resets it to false and would revive a
  /// cancelled loop — two loops then write the same rows and the watermark,
  /// and a loop outliving a logout writes the old account's entries into the
  /// freshly cleared database.
  int _syncGeneration = 0;

  bool _isStale(int generation) =>
      isSyncCancelled || generation != _syncGeneration;

  Future<bool> isLibraryIncomplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isIncompleteKey) ?? false;
  }

  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    if (_initialSyncTask != null) return _initialSyncTask;

    _initialSyncTask = _doInitialSync();
    return _initialSyncTask;
  }

  Future<void> _doInitialSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      if (lastSync != null || prefs.getString(_cursorKey) != null) {
        logger.info(
          'Library already imported. Performing incremental catch-up.',
        );
        _hasPerformedInitialSync = true;
        unawaited(
          syncLibrary().catchError((Object e) {
            logger.warning('Background catch-up sync failed: $e');
          }),
        );
        return;
      }

      logger.info('No previous sync found. Performing full initial import...');
      await importFullLibrary();
      if (!isSyncCancelled) {
        _hasPerformedInitialSync = true;
      }
    } on NetworkException catch (e) {
      logger.warning('Initial import failed: $e');
      _initialSyncTask = null;
      rethrow;
    } catch (e, st) {
      logger.severe('Failed to perform initial import: $e\n$st');
      _initialSyncTask = null;
      rethrow;
    }
  }

  /// A full scan: the feed read from the start, then anything the server no
  /// longer lists is dropped locally.
  Future<void> importFullLibrary() async {
    if (syncStatus.value.isSyncing) return;
    await _runSync(deep: true);
  }

  /// The running [_runSync], so a [deep] request can wait for it instead of
  /// being dropped.
  Future<void>? _activeSync;

  /// Catches the local library up with the server through the dedicated
  /// change feed (`GET /v2/my/library/changes`).
  ///
  /// The first run (no stored cursor) scans the whole library; later runs
  /// send the stored cursor and receive only what changed, deletions
  /// included. A [deep] sync discards the cursor and scans everything again,
  /// for an explicit user refresh. The feed has no state filter, so [state]
  /// is accepted for compatibility and ignored.
  @override
  Future<void> syncLibrary({String? state, bool deep = false}) async {
    final running = _activeSync;
    if (running != null) {
      if (!deep) {
        logger.info(
          'Sync already in progress, skipping incremental sync request.',
        );
        return;
      }
      logger.info('Sync already in progress, deep refresh waits for it.');
      try {
        await running;
      } catch (_) {
        // Its failure was reported through syncStatus; the deep run goes on.
      }
      if (_activeSync != null) return;
    }

    final run = _runSync(deep: deep);
    _activeSync = run;
    try {
      await run;
    } finally {
      if (identical(_activeSync, run)) _activeSync = null;
    }
  }

  Future<void> _runSync({required bool deep}) async {
    if (syncStatus.value.isSyncing) {
      logger.info(
        'Sync already in progress, skipping incremental sync request.',
      );
      return;
    }

    setIsSyncCancelled(false);
    final generation = ++_syncGeneration;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      await auth.getValidAccessToken();
      final prefs = await SharedPreferences.getInstance();
      var cursor = deep ? null : prefs.getString(_cursorKey);
      var restarted = false;
      var totalFetched = 0;
      // Entry ids seen by a scan that began at the start of the feed. Only
      // such a scan can prune: a resumed one has not seen the earlier pages.
      Set<String>? seen = cursor == null ? <String>{} : null;
      logger.info(
        'Starting library sync (${cursor == null ? 'full scan' : 'from cursor'})',
      );
      if (seen != null) await prefs.setBool(_isIncompleteKey, true);

      while (true) {
        if (_isStale(generation)) return;
        final page = await fetchChanges(cursor);
        if (_isStale(generation)) return;

        if (page.invalidCursor) {
          if (cursor != null && !restarted) {
            logger.warning('Library cursor rejected; scanning from the start.');
            restarted = true;
            cursor = null;
            seen = <String>{};
            await prefs.remove(_cursorKey);
            await prefs.setBool(_isIncompleteKey, true);
            continue;
          }
          logger.warning('Library change feed rejected the request.');
          await prefs.setBool(_isIncompleteKey, true);
          syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
          return;
        }

        final applied = await _applyChanges(page.items, seen, generation);
        if (applied == null || _isStale(generation)) return;
        totalFetched += applied;
        syncStatus.value = syncStatus.value.copyWith(
          // Distinct entries on a full scan (the feed may repeat one);
          // otherwise just what this run wrote.
          currentEntries: seen?.length ?? totalFetched,
          error: null,
        );

        // Saved only once the page is durably applied.
        final previous = cursor;
        if (page.cursor != null) {
          cursor = page.cursor;
          await prefs.setString(_cursorKey, page.cursor!);
        }
        if (!page.more) break;
        // A feed that says "more" but gives nothing new would loop forever.
        if (page.cursor == null || (page.cursor == previous && applied == 0)) {
          logger.warning('Library feed made no progress; stopping the scan.');
          break;
        }
        // Let the UI breathe between pages of a very large library.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      if (_isStale(generation)) return;
      if (seen != null && seen.isNotEmpty) {
        await database.libraryEntriesDao.deleteEntriesNotIn(seen.toList());
      }
      await prefs.setBool(_isIncompleteKey, false);
      await prefs.setString(
        _lastSyncKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      logger.info('Library sync completed. Applied $totalFetched entries.');
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e, st) {
      logger.severe('Library sync failed: $e\n$st');
      if (generation == _syncGeneration) {
        syncStatus.value = syncStatus.value.copyWith(
          isSyncing: false,
          error: e.toString(),
        );
      }
      rethrow;
    }
  }

  /// Applies one feed page. Returns how many entries were written, or null
  /// when the sync was invalidated part way through.
  Future<int?> _applyChanges(
    List<Map<String, dynamic>> items,
    Set<String>? seen,
    int generation,
  ) async {
    // Later items win: the feed can repeat a series.
    final bySeries = <String, Map<String, dynamic>?>{};
    for (final item in items) {
      if (item['type'] != 'entry') continue; // lists are not mirrored locally
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

    // A full scan only needs series it has not stored; an incremental one
    // refreshes the series of every entry that changed.
    final ids = [for (final e in upserts) e['series_id'].toString()];
    final stored = seen != null
        ? await database.seriesDao.existingIds(ids)
        : <String>{};
    final series = await fetchSeriesBatch([
      for (final id in ids)
        if (!stored.contains(id)) id,
    ]);
    if (_isStale(generation)) return null;

    var written = 0;
    await database.transaction(() async {
      await database.seriesDao.upsertSeries(series);
      // An entry needs its series row (foreign key). A series the catalog no
      // longer returns (deleted or merged away) would fail the whole page, so
      // its entry is skipped instead.
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

  /// Also invalidates any sync in flight (see [_syncGeneration]). The
  /// invalidated loop exits without touching [syncStatus] again, so callers
  /// that abandon a running sync must clear its syncing flag themselves.
  @override
  void resetInitialSyncTask() {
    _hasPerformedInitialSync = false;
    _initialSyncTask = null;
    _syncGeneration++;
  }
}
