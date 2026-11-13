import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_changes.dart';
import 'package:mangabaka_app/core/exceptions/error_messages.dart';

const String _lastSyncKey = AppConstants.lastSyncKey;
const String _cursorKey = AppConstants.libraryCursorKey;
const String _isIncompleteKey =
    '${AppConstants.prefixStorageKey}library_is_incomplete';

/// Which generation of series data the local database holds. Raised whenever
/// stored series rows are known to be wrong or incomplete, so the next sync
/// re-fetches every one of them once.
///
/// 2: rows used to be built from the lean v2 batch, whose guessed titles
///    disagreed with the detail page and which lacked genres, tags and year.
const String librarySeriesDataKey =
    '${AppConstants.prefixStorageKey}library_series_data_version';
const int librarySeriesDataVersion = 2;

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
      logger.severe('Failed to perform initial import', e, st);
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
      } catch (e) {
        logger.fine('Preceding sync failed before deep refresh: $e');
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
      // Stored series from an older data generation are re-fetched in full,
      // which needs a scan from the start of the feed.
      final refreshSeries =
          (prefs.getInt(librarySeriesDataKey) ?? 0) < librarySeriesDataVersion;
      var cursor = (deep || refreshSeries) ? null : prefs.getString(_cursorKey);
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

        final applied = await _applyChanges(
          page.items,
          seen,
          generation,
          refreshSeries: refreshSeries,
        );
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
      await prefs.setInt(librarySeriesDataKey, librarySeriesDataVersion);
      await prefs.setString(
        _lastSyncKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      logger.info('Library sync completed. Applied $totalFetched entries.');
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e, st) {
      logger.severe('Library sync failed', e, st);
      if (generation == _syncGeneration) {
        syncStatus.value = syncStatus.value.copyWith(
          isSyncing: false,
          // Shown in the sync banner and card: wording, not a stack dump.
          error: ErrorMessages.describe(e),
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
    int generation, {
    bool refreshSeries = false,
  }) => applyLibraryFeedChanges(
    items: items,
    seen: seen,
    refreshSeries: refreshSeries,
    database: database,
    logger: logger,
    fetchSeriesBatch: fetchSeriesBatch,
    isStale: () => _isStale(generation),
  );

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
