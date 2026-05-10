import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/features/library/services/library_constants.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;

const String _lastSyncKey = AppConstants.lastSyncKey;
const String _isIncompleteKey = '${AppConstants.prefixStorageKey}library_is_incomplete';

mixin LibrarySyncMixin on LibraryServiceBase {
  bool _hasPerformedInitialSync = false;
  Future<void>? _initialSyncTask;

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
        unawaited(syncLibrary());
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
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await auth.getValidAccessToken();
      var totalFetched = 0;
      final fetchedIds = <String>[];
      final result = await importSlice(
        token,
        onProgress: (n, ids) {
          totalFetched += n;
          fetchedIds.addAll(ids);
          syncStatus.value = syncStatus.value.copyWith(
            currentEntries: totalFetched, error: null);
        },
      );

      if (!result.hitCap && !isSyncCancelled && fetchedIds.isNotEmpty) {
        await database.libraryEntriesDao.deleteEntriesNotIn(fetchedIds);
      }

      if (!isSyncCancelled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isIncompleteKey, result.hitCap);
        final watermark = result.newestWatermark ?? DateTime.now().toUtc().toIso8601String();
        await prefs.setString(_lastSyncKey, watermark);
      }

      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e) {
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      rethrow;
    }
  }

  Future<({bool hitCap, List<String> fetchedIds, String? newestWatermark})> importSlice(
    String token, {
    required void Function(int fetched, List<String> fetchedIds) onProgress,
  }) async {
    var page = 1;
    final int apiPageCap = AppConstants.libraryMaxPages;
    final allFetchedIds = <String>[];
    String? newestWatermark;

    while (page <= apiPageCap) {
      if (isSyncCancelled) return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      final result = await fetchPage(token, page, sortBy: 'updated_at_desc');
      final entries = result.entries;

      if (result.isError) return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      if (page == 1 && entries.isNotEmpty) {
        final e = entries.first;
        newestWatermark = e.updatedAt ?? e.createdAt ?? '${e.id}|${e.state}|${e.progressChapter ?? 0}';
      }

      await saveEntries(entries);
      final ids = entries.map((e) => e.id).toList();
      allFetchedIds.addAll(ids);
      onProgress(entries.length, ids);

      if (entries.isEmpty || entries.length < LibraryConstants.pageLimit) {
        return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      }
      page++;
    }
    return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
  }

  @override
  Future<void> syncLibrary({String? state}) async {
    if (syncStatus.value.isSyncing) return;

    setIsSyncCancelled(false);
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await auth.getValidAccessToken();
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      final lastSync = lastSyncStr != null ? parseAsUtc(lastSyncStr) : null;
      String? newestEntryTimestamp;

      var page = 1;
      var totalFetched = 0;
      const maxSyncPages = 10;

      while (page <= maxSyncPages) {
        if (isSyncCancelled) break;

        final result = await fetchPage(token, page, sortBy: 'updated_at_desc', state: state);
        final entries = result.entries;

        if (entries.isEmpty) break;

        bool reachedKnown = false;
        final newEntries = <api.LibraryEntry>[];

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

        await saveEntries(newEntries);
        totalFetched += newEntries.length;
        syncStatus.value = syncStatus.value.copyWith(currentEntries: totalFetched, error: null);

        if (reachedKnown || entries.length < LibraryConstants.pageLimit) break;
        page++;
      }

      if (!isSyncCancelled) {
        await prefs.setString(_lastSyncKey, newestEntryTimestamp ?? DateTime.now().toUtc().toIso8601String());
      }
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
    } catch (e) {
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false, error: e.toString());
      rethrow;
    }
  }

  @override
  void resetInitialSyncTask() {
    _hasPerformedInitialSync = false;
    _initialSyncTask = null;
  }
}
