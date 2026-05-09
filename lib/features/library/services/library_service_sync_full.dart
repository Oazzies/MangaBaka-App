part of 'library_service.dart';

// ─── Incomplete library flag ───────────────────────────────────────────────

extension LibraryServiceSyncFull on LibraryService {
  /// Returns true if the full import hit the 100-page API limit.
  Future<bool> isLibraryIncomplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isIncompleteKey) ?? false;
  }

  // ─── Initial sync ─────────────────────────────────────────────────────────

  /// Performs a full import only once on first app load.
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
        _logger.info('Library already imported. Performing incremental catch-up.');
        _hasPerformedInitialSync = true;
        // Background sync to catch up on any changes while app was closed
        unawaited(syncLibrary());
        return;
      }

      _logger.info('No previous sync found. Performing full initial import...');
      await importFullLibrary();
      if (!_isSyncCancelled) {
        _hasPerformedInitialSync = true;
      }
    } on NetworkException catch (e) {
      _logger.warning(
          'Initial import failed due to network error: $e. Using local data.');
      _initialSyncTask = null;
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to perform initial import: $e\n$st');
      _initialSyncTask = null;
      rethrow;
    }
  }

  // ─── Full library import ───────────────────────────────────────────────────

  /// Fetches the entire library, paginating up to the API limit.
  Future<void> importFullLibrary() async {
    if (syncStatus.value.isSyncing) return;

    _isSyncCancelled = false;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await _auth.getValidAccessToken();
      var totalFetched = 0;

      _logger.info('Importing full library...');
      final fetchedIds = <String>[];
      final result = await _importSlice(
        token,
        onProgress: (n, ids) {
          totalFetched += n;
          fetchedIds.addAll(ids);
          syncStatus.value = syncStatus.value.copyWith(
            currentEntries: totalFetched, error: null);
        },
      );

      if (!result.hitCap && !_isSyncCancelled && fetchedIds.isNotEmpty) {
        await _db.libraryEntriesDao.deleteEntriesNotIn(fetchedIds);
      }

      if (!_isSyncCancelled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isIncompleteKey, result.hitCap);
        
        final watermark = result.newestWatermark ?? DateTime.now().toUtc().toIso8601String();
        await prefs.setString(_lastSyncKey, watermark);
        _logger.info('Full import complete. Watermark set to $watermark');
      }

      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
      _logger.info(
          'Full library import completed. Total: $totalFetched. Incomplete: ${result.hitCap}');
    } on AuthException catch (e) {
      syncStatus.value =
          syncStatus.value.copyWith(isSyncing: false, error: e.message);
      rethrow;
    } on NetworkException catch (e) {
      syncStatus.value = syncStatus.value.copyWith(
        isSyncing: false,
        error: e.message,
        isServerDown: true,
      );
      _logger.warning('Network error during import: $e');
      rethrow;
    } on ApiException catch (e) {
      final isDown = e.statusCode >= 500;
      syncStatus.value = syncStatus.value.copyWith(
        isSyncing: false,
        error: e.message,
        isServerDown: isDown,
      );
      _logger.warning('API error during import: $e');
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to import library: $e\n$st');
      syncStatus.value =
          syncStatus.value.copyWith(isSyncing: false, error: 'Import failed.');
      throw AppError(
        message: 'Failed to import library',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Paginates up to [AppConstants.libraryMaxPages] pages.
  /// Returns whether the cap was hit (meaning there may be more entries).
  Future<({bool hitCap, List<String> fetchedIds, String? newestWatermark})> _importSlice(
    String token, {
    required void Function(int fetched, List<String> fetchedIds) onProgress,
  }) async {
    var page = 1;
    final int apiPageCap = AppConstants.libraryMaxPages;
    final allFetchedIds = <String>[];
    String? newestWatermark;

    while (page <= apiPageCap) {
      if (_isSyncCancelled) return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);

      final result = await _fetchPage(token, page, sortBy: 'updated_at_desc');
      final entries = result.entries;

      if (result.isError) {
        _logger.warning('Stopped import at page $page due to API error/limit.');
        return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
      }

      if (page == 1 && entries.isNotEmpty) {
        final e = entries.first;
        final dateStr = e.updatedAt ?? e.createdAt;
        if (dateStr != null) {
          newestWatermark = dateStr;
        } else {
          // Compound watermark: id|state|progress
          newestWatermark = '${e.id}|${e.state}|${e.progressChapter ?? 0}';
        }
      }

      _logger.info('Import page $page: ${entries.length} entries');

      await _saveEntries(entries);
      final ids = entries.map((e) => e.id).toList();
      allFetchedIds.addAll(ids);
      onProgress(entries.length, ids);

      if (entries.isEmpty || entries.length < LibraryConstants.pageLimit) {
        return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark); // Natural end of data
      }

      if (page == apiPageCap) {
        return (hitCap: true, fetchedIds: allFetchedIds, newestWatermark: newestWatermark); // Hit our own app cap
      }

      page++;
    }

    return (hitCap: false, fetchedIds: allFetchedIds, newestWatermark: newestWatermark);
  }
}
