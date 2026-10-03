import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;

const String _lastSyncKey = AppConstants.lastSyncKey;
const String _isIncompleteKey = '${AppConstants.prefixStorageKey}library_is_incomplete';

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

      if (lastSync != null) {
        logger.info('Library already imported. Performing incremental catch-up.');
        _hasPerformedInitialSync = true;
        unawaited(syncLibrary().catchError((Object e) {
          logger.warning('Background catch-up sync failed: $e');
        }));
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

  Future<void> importFullLibrary() async {
    if (syncStatus.value.isSyncing) return;

    setIsSyncCancelled(false);
    final generation = ++_syncGeneration;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      // Fails fast when signed out, before the progress UI shows any pages.
      await auth.getValidAccessToken();
      var totalFetched = 0;
      final fetchedIds = <String>[];
      final result = await importSlice(
        onProgress: (n, ids) {
          totalFetched += n;
          fetchedIds.addAll(ids);
          syncStatus.value = syncStatus.value.copyWith(
            currentEntries: totalFetched, error: null);
        },
      );

      if (_isStale(generation)) {
        logger.info('Full import superseded or cancelled; discarding result');
        return;
      }

      if (!result.hitCap && fetchedIds.isNotEmpty) {
        await database.libraryEntriesDao.deleteEntriesNotIn(fetchedIds);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isIncompleteKey, result.hitCap);
      final watermark = result.newestWatermark ?? DateTime.now().toUtc().toIso8601String();
      await prefs.setString(_lastSyncKey, watermark);

      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e) {
      if (generation == _syncGeneration) {
        syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<({bool hitCap, List<String> fetchedIds, String? newestWatermark})> importSlice({
    required void Function(int fetched, List<String> fetchedIds) onProgress,
  }) async {
    final generation = _syncGeneration;
    var page = 1;
    final int apiPageCap = AppConstants.libraryMaxPages;
    final allFetchedIds = <String>[];
    String? newestWatermark;
    // Set when a page had unparseable entries. Those ids are missing from
    // allFetchedIds, so the result must not be used to prune local entries.
    var partial = false;

    while (page <= apiPageCap) {
      // Reported as capped so the caller never prunes against a partial list.
      if (_isStale(generation)) return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      final result = await fetchPage(page, sortBy: 'updated_at_desc');
      if (_isStale(generation)) return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      final entries = result.entries;

      if (result.isError) return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      if (result.skipped > 0) partial = true;

      if (page == 1 && entries.isNotEmpty) {
        final e = entries.first;
        newestWatermark = e.updatedAt ?? e.createdAt ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';
      }

      await saveEntries(entries);
      final ids = entries.map((e) => e.id).toList();
      allFetchedIds.addAll(ids);
      onProgress(entries.length, ids);

      if (entries.length + result.skipped < LibraryConstants.pageLimit) {
        return (hitCap: partial, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      }
      page++;
    }
    return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
  }

  /// The running [_runSync], so a [deep] request can wait for it instead of
  /// being dropped.
  Future<void>? _activeSync;

  /// Catches the local library up with the server.
  ///
  /// The default walk stops at the first entry whose `updated_at` is not newer
  /// than the stored watermark. That trusts the server to bump `updated_at` on
  /// every change and to sort by it, so a change that does not (or one that
  /// lands with an older timestamp) is never fetched again. A [deep] sync does
  /// not trust timestamps: it walks the whole library and saves every entry
  /// that differs from the local copy. Use it for an explicit user refresh.
  @override
  Future<void> syncLibrary({String? state, bool deep = false}) async {
    final running = _activeSync;
    if (running != null) {
      if (!deep) {
        logger.info('Sync already in progress, skipping incremental sync request.');
        return;
      }
      // A manual refresh must not be swallowed by the startup catch-up that
      // happens to be running: that one may have fetched its pages before the
      // change was made.
      logger.info('Sync already in progress, deep refresh waits for it.');
      try {
        await running;
      } catch (_) {
        // Its failure was reported through syncStatus; the deep run goes on.
      }
      if (_activeSync != null) return;
    }

    final run = _runSync(state: state, deep: deep);
    _activeSync = run;
    try {
      await run;
    } finally {
      if (identical(_activeSync, run)) _activeSync = null;
    }
  }

  static bool _entryDiffers(api.LibraryEntry remote, dynamic local) =>
      local == null ||
      local.id != remote.id ||
      local.state != remote.state ||
      local.note != remote.note ||
      local.progressChapter != remote.progressChapter ||
      local.progressVolume != remote.progressVolume ||
      local.numberOfRereads != remote.numberOfRereads ||
      local.rating != remote.rating;

  Future<void> _runSync({String? state, required bool deep}) async {
    if (syncStatus.value.isSyncing) {
      logger.info('Sync already in progress, skipping incremental sync request.');
      return;
    }

    logger.info('Starting ${deep ? 'deep' : 'incremental'} library sync${state != null ? ' for state $state' : ''}');
    setIsSyncCancelled(false);
    final generation = ++_syncGeneration;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      await auth.getValidAccessToken();
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      final lastSync = lastSyncStr != null ? parseAsUtc(lastSyncStr) : null;

      logger.fine('Last sync watermark: $lastSyncStr');
      String? newestEntryTimestamp;

      var page = 1;
      var totalFetched = 0;
      final maxSyncPages = deep ? AppConstants.libraryMaxPages : 10;
      final deepFetchedIds = <String>[];
      var deepPartial = false;
      // True once the walk reached entries the last sync already saw (or ran
      // out of entries). Only then is everything newer than the old
      // watermark known to be saved, and only then may it move forward.
      var caughtUp = false;

      while (page <= maxSyncPages) {
        if (_isStale(generation)) {
          logger.info('Incremental sync cancelled at page $page');
          return;
        }

        final result = await fetchPage(page, sortBy: 'updated_at_desc', state: state);
        if (_isStale(generation)) {
          logger.info('Incremental sync cancelled at page $page');
          return;
        }
        final entries = result.entries;

        if (entries.isEmpty) {
          logger.fine('No entries returned for page $page, stopping sync');
          caughtUp = !result.isError && result.skipped == 0;
          break;
        }

        bool reachedKnown = false;
        final newEntries = <api.LibraryEntry>[];

        if (deep) {
          if (result.skipped > 0) deepPartial = true;
          deepFetchedIds.addAll(entries.map((e) => e.id));
          final local = await database.libraryEntriesDao
              .getEntriesBySeriesIds(entries.map((e) => e.series.id));
          if (_isStale(generation)) return;
          for (final e in entries) {
            final dateStr = e.updatedAt ?? e.createdAt;
            newestEntryTimestamp ??= dateStr ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';
            if (_entryDiffers(e, local[e.series.id])) newEntries.add(e);
          }
        } else {
        for (final e in entries) {
          final dateStr = e.updatedAt ?? e.createdAt;
          newestEntryTimestamp ??= dateStr ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';

          bool isNew = true;
          if (dateStr != null) {
            final entryDate = parseAsUtc(dateStr);
            if (lastSync != null && entryDate != null && !entryDate.isAfter(lastSync)) isNew = false;
          } else if (lastSyncStr != null) {
            if ('${e.id}|${e.state}|${e.progressChapter ?? 0}' == lastSyncStr) isNew = false;
          }

          if (!isNew) {
            reachedKnown = true;
            break;
          }
          newEntries.add(e);
        }
        }

        if (newEntries.isNotEmpty) {
          logger.info('Saving ${newEntries.length} new/updated entries from page $page');
          await saveEntries(newEntries);
          totalFetched += newEntries.length;
          syncStatus.value = syncStatus.value.copyWith(currentEntries: totalFetched, error: null);
        }

        if (reachedKnown) {
          logger.info('Reached known entries at page $page. Sync catch-up complete.');
          caughtUp = true;
          break;
        }

        if (entries.length + result.skipped < LibraryConstants.pageLimit) {
          logger.fine('Page $page was the last page of results');
          caughtUp = true;
          break;
        }
        page++;
      }

      if (_isStale(generation)) return;

      // The watermark is global. A sync filtered to one state only proves
      // that state is caught up, so moving it would hide updates made to
      // entries in the other states.
      if (state != null) {
        logger.info('State-filtered sync completed. Total fetched: $totalFetched. Watermark unchanged.');
      } else if (caughtUp) {
        final newWatermark = newestEntryTimestamp ?? DateTime.now().toUtc().toIso8601String();
        logger.info('Incremental sync completed. Total fetched: $totalFetched. New watermark: $newWatermark');
        await prefs.setString(_lastSyncKey, newWatermark);
        if (deep && !deepPartial) {
          // The whole library was seen, so this is as complete as a full
          // import: drop entries removed on the server and clear the flag.
          if (deepFetchedIds.isNotEmpty) {
            await database.libraryEntriesDao.deleteEntriesNotIn(deepFetchedIds);
          }
          await prefs.setBool(_isIncompleteKey, false);
        }
      } else {
        // Stopped at the page cap before reaching known entries: anything
        // older than the pages walked but newer than the old watermark was
        // not saved. Advancing would skip it forever, so keep the watermark
        // and flag the local copy as incomplete instead. A page the server
        // refused (or could not fully parse) ends the walk the same way.
        logger.warning('Incremental sync stopped before catching up (page cap, rejected page, or unparseable entries). Watermark unchanged; library marked incomplete.');
        await prefs.setBool(_isIncompleteKey, true);
      }
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e, st) {
      logger.severe('Incremental sync failed: $e\n$st');
      if (generation == _syncGeneration) {
        syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      }
      rethrow;
    }
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
