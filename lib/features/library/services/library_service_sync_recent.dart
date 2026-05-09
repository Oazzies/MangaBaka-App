part of 'library_service.dart';

// ─── Recents sync ─────────────────────────────────────────────────────────

extension LibraryServiceSyncRecent on LibraryService {
  /// Syncs only recent changes (sorted by `updated_at_desc`).
  /// Stops early once all entries on a page are older than the last sync.
  /// This is cheap and fast — call it on pull-to-refresh.
  Future<void> syncLibrary({String? state}) async {
    if (syncStatus.value.isSyncing) return;

    _isSyncCancelled = false;
    syncStatus.value = LibrarySyncStatus(isSyncing: true);

    try {
      final token = await _auth.getValidAccessToken();
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      _logger.info('Starting syncLibrary. lastSync watermark: $lastSyncStr');
      final lastSync = lastSyncStr != null ? _parseAsUtc(lastSyncStr) : null;
      String? newestEntryTimestamp;

      var page = 1;
      var totalFetched = 0;
      // Fetch at most 10 pages of recents (1000 entries) — more than enough
      // for normal sync intervals.
      const maxSyncPages = 10;

      while (page <= maxSyncPages) {
        if (_isSyncCancelled) break;

        final result = await _fetchPage(
          token,
          page,
          sortBy: 'updated_at_desc',
          state: state,
        );
        final entries = result.entries;

        if (entries.isEmpty) break;

        bool reachedKnown = false;
        final newEntries = <api.LibraryEntry>[];

        for (final e in entries) {
          final dateStr = e.updatedAt ?? e.createdAt;
          
          // Keep track of the absolute newest entry we've seen to update the watermark
          if (newestEntryTimestamp == null) {
            // The very first entry of page 1 is our new watermark
            if (dateStr != null) {
              newestEntryTimestamp = dateStr;
            } else {
              newestEntryTimestamp = '${e.id}|${e.state}|${e.progressChapter ?? 0}';
            }
          } else if (dateStr != null) {
            final newestDate = _parseAsUtc(newestEntryTimestamp!);
            final currentEntryDate = _parseAsUtc(dateStr);
            if (newestDate != null && currentEntryDate != null && currentEntryDate.isAfter(newestDate)) {
              newestEntryTimestamp = dateStr;
            }
          }

          // Heuristic stopping condition: 
          // 1. If we have timestamps, use them.
          // 2. If no timestamps, stop if we hit the exact entry (ID+State+Progress) that was newest last time.
          bool isNew = true;
          if (dateStr != null) {
            final entryDate = _parseAsUtc(dateStr);
            if (lastSync != null && entryDate != null && !entryDate.isAfter(lastSync)) {
              isNew = false;
            }
          } else if (lastSyncStr != null) {
            final currentFingerprint = '${e.id}|${e.state}|${e.progressChapter ?? 0}';
            if (currentFingerprint == lastSyncStr) {
              isNew = false;
            }
          }

          if (!isNew) {
            reachedKnown = true;
            break;
          }
          
          newEntries.add(e);
        }

        await _saveEntries(newEntries);
        totalFetched += newEntries.length;

        syncStatus.value =
            syncStatus.value.copyWith(currentEntries: totalFetched, error: null);

        if (reachedKnown || entries.length < LibraryConstants.pageLimit) break;

        page++;
      }

      if (!_isSyncCancelled) {
        if (newestEntryTimestamp != null) {
          await prefs.setString(_lastSyncKey, newestEntryTimestamp!);
        } else {
          await prefs.setString(
              _lastSyncKey, DateTime.now().toUtc().toIso8601String());
        }
      }
      
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
      _logger.info('Recents sync completed. Fetched $totalFetched entries.');
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
      _logger.warning('Network error during sync: $e');
      rethrow;
    } on ApiException catch (e) {
      final isDown = e.statusCode >= 500;
      syncStatus.value = syncStatus.value.copyWith(
        isSyncing: false,
        error: e.message,
        isServerDown: isDown,
      );
      _logger.warning('API error during sync: $e');
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to sync library: $e\n$st');
      syncStatus.value =
          syncStatus.value.copyWith(isSyncing: false, error: 'Sync failed.');
      throw AppError(
        message: 'Failed to sync library',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
