import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;

  // ─── Prefs keys ───────────────────────────────────────────────────────────
  static const String _lastSyncKey = AppConstants.lastSyncKey;
  static const String _isIncompleteKey =
      '${AppConstants.prefixStorageKey}library_is_incomplete';

  // ─── Sync state notifier ──────────────────────────────────────────────────
  final ValueNotifier<LibrarySyncStatus> syncStatus =
      ValueNotifier(LibrarySyncStatus());

  bool _isSyncCancelled = false;

  void cancelSync() {
    _isSyncCancelled = true;
    _initialSyncTask = null;
    syncStatus.value = syncStatus.value
        .copyWith(isSyncing: false, clearError: true, clearInfo: true);
  }

  LibraryService({required ProfileAuthService auth})
      : _auth = auth,
        _db = db.AppDatabase();

  // ─── DB streams ───────────────────────────────────────────────────────────

  /// Watches a single library entry by series ID.
  Stream<api.LibraryEntry?> watchEntryFromDb(String seriesId) {
    return _db.libraryEntriesDao
        .watchEntryWithSeries(seriesId)
        .map(
          (dbEntry) => dbEntry != null
              ? DbToApiMapper.libraryEntryFromDb(dbEntry)
              : null,
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entry from db: $error\n$stackTrace');
          return null;
        }, test: (error) => true);
  }

  Stream<List<api.LibraryEntry>> watchEntriesFromDb() {
    return _db.libraryEntriesDao
        .watchAllEntriesWithSeries()
        .map(
          (dbEntries) =>
              dbEntries.map(DbToApiMapper.libraryEntryFromDb).toList(),
        )
        .handleError((error, stackTrace) {
          _logger.severe('Error watching entries from db: $error\n$stackTrace');
          return <api.LibraryEntry>[];
        }, test: (error) => true);
  }

  // ─── Incomplete library flag ───────────────────────────────────────────────

  /// Returns true if the full import hit the 100-page API limit.
  Future<bool> isLibraryIncomplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isIncompleteKey) ?? false;
  }

  // ─── Initial sync ─────────────────────────────────────────────────────────

  Future<void>? _initialSyncTask;

  /// Performs a full import only once on first app load.
  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    if (_initialSyncTask != null) return _initialSyncTask;

    _initialSyncTask = _doInitialSync();
    return _initialSyncTask;
  }

  Future<void> _doInitialSync() async {
    try {
      await importFullLibrary();
      _hasPerformedInitialSync = true;
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
      final result = await _importSlice(
        token,
        onProgress: (n) {
          totalFetched += n;
          syncStatus.value = syncStatus.value.copyWith(
            currentEntries: totalFetched, error: null);
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isIncompleteKey, result.hitCap);
      await prefs.setString(
          _lastSyncKey, DateTime.now().toUtc().toIso8601String());

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
  Future<({bool hitCap})> _importSlice(
    String token, {
    required void Function(int fetched) onProgress,
  }) async {
    var page = 1;
    final int apiPageCap = AppConstants.libraryMaxPages;

    while (page <= apiPageCap) {
      if (_isSyncCancelled) return (hitCap: false);

      final result = await _fetchPage(token, page, sortBy: 'updated_at_desc');
      final entries = result.entries;

      if (result.isError) {
        _logger.warning('Stopped import at page $page due to API error/limit.');
        return (hitCap: true);
      }

      _logger.info('Import page $page: ${entries.length} entries');

      await _saveEntries(entries);
      onProgress(entries.length);

      if (entries.isEmpty || entries.length < LibraryConstants.pageLimit) {
        return (hitCap: false); // Natural end of data
      }

      if (page == apiPageCap) {
        return (hitCap: true); // Hit our own app cap
      }

      page++;
    }

    return (hitCap: false);
  }

  // ─── Recents sync ─────────────────────────────────────────────────────────

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
      final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

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

        // If we know the last sync time, stop once we hit already-seen entries.
        bool reachedKnown = false;
        if (lastSync != null) {
          final newEntries = <api.LibraryEntry>[];
          for (final e in entries) {
            final dateStr = e.updatedAt ?? e.createdAt;
            if (dateStr != null) {
              final entryDate = DateTime.tryParse(dateStr);
              if (entryDate != null &&
                  !entryDate.isAfter(lastSync)) {
                reachedKnown = true;
                break;
              }
            }
            newEntries.add(e);
          }
          await _saveEntries(newEntries);
          totalFetched += newEntries.length;
        } else {
          await _saveEntries(entries);
          totalFetched += entries.length;
        }

        syncStatus.value =
            syncStatus.value.copyWith(currentEntries: totalFetched, error: null);

        if (reachedKnown || entries.length < LibraryConstants.pageLimit) break;

        page++;
      }

      await prefs.setString(
          _lastSyncKey, DateTime.now().toUtc().toIso8601String());
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

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Future<_FetchPageResult> _fetchPage(
    String token,
    int page, {
    String? state,
    String? type,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': LibraryConstants.pageLimit.toString(),
    };
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final uri = Uri.parse(LibraryConstants.baseUrl)
        .replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(uri, headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': LibraryConstants.userAgent,
          })
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Library fetch timed out'),
          );

      _logger.fine('Library fetch page $page completed (${response.statusCode})');

      if (response.statusCode == 429) {
        _logger.warning(
            'Rate limited on page $page. Waiting ${AppConstants.rateLimitRetryDelaySeconds}s...');
        await Future.delayed(
            Duration(seconds: AppConstants.rateLimitRetryDelaySeconds));
        return _fetchPage(token, page, state: state, sortBy: sortBy);
      }

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      // 400 usually means "Bad Request" - often "Page out of range" or hitting a deep pagination limit.
      if (response.statusCode == 400) {
        _logger.warning('Page $page returned 400. Body: ${response.body}');
        return _FetchPageResult(entries: [], totalEntries: 0, isError: true);
      }

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to fetch library page. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to fetch library page',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_PAGE_FAILED',
        );
      }

      try {
        final result = await compute(_parseLibraryPage, response.body);
        return result;
      } catch (e, st) {
        _logger.severe('Failed to parse library page: $e\n$st');
        throw ParseException(
          message: 'Failed to parse library page',
          originalError: e,
          stackTrace: st,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException(
          message: 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
          originalError: e);
    } on SocketException catch (e) {
      throw NetworkException(
          message: 'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
          originalError: e);
    } on TimeoutException catch (e) {
      throw NetworkException(
          message: 'Request timed out. Please try again.',
          code: 'TIMEOUT',
          originalError: e);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on ParseException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      throw AppError(
          message: 'Unexpected error fetching library page',
          originalError: e,
          stackTrace: st);
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    try {
      await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
      await _db.libraryEntriesDao.upsertLibraryEntries(entries);
    } catch (e, st) {
      _logger.severe('Failed to save entries to database: $e\n$st');
      throw DatabaseException(
        message: 'Failed to save entries',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  // ─── CRUD operations ──────────────────────────────────────────────────────

  Future<void> updateLibraryEntryState(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update state request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryState(seriesId, state);
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry state: $e\n$st');
      throw AppError(
          message: 'Failed to update entry state', originalError: e, stackTrace: st);
    }
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': LibraryConstants.userAgent,
            },
            body: jsonEncode({'rating': rating}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Update rating request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry rating: $e\n$st');
      throw AppError(
          message: 'Failed to update entry rating', originalError: e, stackTrace: st);
    }
  }

  /// Creates a new library entry, then does a cheap recents sync to pull it back.
  Future<void> createLibraryEntry(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'state': state}),
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Create entry request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 201) {
        // Fetch just the first page of recents to pick up the new entry quickly.
        await syncLibrary();
      } else {
        _logger.severe(
            'Failed to create library entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error creating entry: $e\n$st');
      throw AppError(
          message: 'Failed to create library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    final token = await _auth.getValidAccessToken();
    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .delete(url, headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': LibraryConstants.userAgent,
          })
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Delete entry request timed out'),
          );

      if (response.statusCode == 401) {
        throw AuthException(
            message: 'Authentication failed.', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 200 || response.statusCode == 404) {
        await _db.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        _logger
            .severe('Failed to delete entry. Status: ${response.statusCode}');
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on http.ClientException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on SocketException catch (e, st) {
      throw NetworkException(
          message: 'Network error.', code: 'NETWORK_ERROR', originalError: e, stackTrace: st);
    } on TimeoutException catch (e, st) {
      throw NetworkException(
          message: 'Request timed out.', code: 'TIMEOUT', originalError: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error deleting entry: $e\n$st');
      throw AppError(
          message: 'Failed to delete library entry', originalError: e, stackTrace: st);
    }
  }

  Future<void> clearLibrary() async {
    try {
      cancelSync();
      await _db.libraryEntriesDao.deleteAllEntries();
      _hasPerformedInitialSync = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_isIncompleteKey);
    } catch (e, st) {
      _logger.severe('Failed to clear library: $e\n$st');
    }
  }
}

// ─── Private parse helpers (run in isolate) ──────────────────────────────────

class _FetchPageResult {
  final List<api.LibraryEntry> entries;
  final int totalEntries;
  final bool isError;

  _FetchPageResult({
    required this.entries,
    required this.totalEntries,
    this.isError = false,
  });
}

_FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody) as Map<String, dynamic>;
  final data = (body['data'] as List<dynamic>? ?? const []);

  int total = 0;
  final pagination = body['pagination'] as Map<String, dynamic>?;
  if (pagination != null) {
    // API returns count = items on this page, not the grand total.
    // We use 'count' only for internal checks; there is no total exposed.
    total = (pagination['count'] as num?)?.toInt() ?? 0;
  }

  final entries = data
      .map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>))
      .toList();

  return _FetchPageResult(entries: entries, totalEntries: total);
}
