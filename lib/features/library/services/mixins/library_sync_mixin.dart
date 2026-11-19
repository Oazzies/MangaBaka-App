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

/// Bump to make the next sync re-fetch every stored series row once.
/// 2: rows built from the lean v2 batch had guessed titles and lacked genres, tags and year.
const String librarySeriesDataKey =
    '${AppConstants.prefixStorageKey}library_series_data_version';
const int librarySeriesDataVersion = 2;

mixin LibrarySyncMixin on LibraryServiceBase {
  bool _hasPerformedInitialSync = false;
  Future<void>? _initialSyncTask;

  /// The cancel flag alone is not enough: the next sync resets it and revives a cancelled loop,
  /// which then double-writes rows or writes the old account's entries after logout.
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

  Future<void> importFullLibrary() async {
    if (syncStatus.value.isSyncing) return;
    await _runSync(deep: true);
  }

  Future<void>? _activeSync;

  /// The change feed has no state filter, so [state] is ignored.
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
      // Re-fetching old-generation series rows needs a scan from the start of the feed.
      final refreshSeries =
          (prefs.getInt(librarySeriesDataKey) ?? 0) < librarySeriesDataVersion;
      var cursor = (deep || refreshSeries) ? null : prefs.getString(_cursorKey);
      var restarted = false;
      var totalFetched = 0;
      // Only a scan from the start can prune; a resumed one has not seen the earlier pages.
      Set<String>? seen = cursor == null ? <String>{} : null;
      logger.info(
        'Starting library sync (${cursor == null ? 'full scan' : 'from cursor'})',
      );
      if (seen != null) await prefs.setBool(_isIncompleteKey, true);

      while (true) {
        if (_isStale(generation)) return;
        final page = await fetchChanges(cursor);
        if (_isStale(generation)) return;

        if (page.rejected) {
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
          // The feed may repeat an entry, so a full scan counts distinct ids.
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
          error: ErrorMessages.describe(e),
        );
      }
      rethrow;
    }
  }

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

  /// The invalidated loop exits without touching [syncStatus], so callers clear isSyncing.
  @override
  void resetInitialSyncTask() {
    _hasPerformedInitialSync = false;
    _initialSyncTask = null;
    _syncGeneration++;
  }
}
