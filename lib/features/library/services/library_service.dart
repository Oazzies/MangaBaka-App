import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/database/database.dart' as db;
import 'package:mangabaka_app/features/library/models/library_entry.dart' as api;
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/services/library_constants.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_crud_mixin.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_mixin.dart';


import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';

// ─── Prefs keys ───────────────────────────────────────────────────────────





abstract class LibraryServiceBase {
  db.AppDatabase get database;
  ProfileAuthService get auth;
  dynamic get logger;
  
  ValueNotifier<LibrarySyncStatus> get syncStatus;
  bool get isSyncCancelled;
  void setIsSyncCancelled(bool val);

  Future<void> syncLibrary({String? state});
  Future<FetchPageResult> fetchPage(String token, int page, {String? state, String? type, String? sortBy});
  Future<void> saveEntries(List<api.LibraryEntry> entries);
  DateTime? parseAsUtc(String dateStr);
  
  void resetInitialSyncTask();
}

class LibraryService extends LibraryServiceBase with LibraryCrudMixin, LibrarySyncMixin {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;

  @override
  db.AppDatabase get database => _db;

  @override
  ProfileAuthService get auth => _auth;

  @override
  dynamic get logger => _logger;

  @override
  ValueNotifier<LibrarySyncStatus> get syncStatus => _syncStatus;

  @override
  bool get isSyncCancelled => _isSyncCancelled;

  @override
  void setIsSyncCancelled(bool val) => _isSyncCancelled = val;

  @override
  Future<FetchPageResult> fetchPage(String token, int page, {String? state, String? type, String? sortBy}) => _fetchPage(token, page, state: state, type: type, sortBy: sortBy);

  @override
  Future<void> saveEntries(List<api.LibraryEntry> entries) => _saveEntries(entries);

  @override
  DateTime? parseAsUtc(String dateStr) => _parseAsUtc(dateStr);

  @override
  void resetInitialSyncTask() {
    // Handled by mixin
  }

  // ─── Sync state notifier ──────────────────────────────────────────────────
  final ValueNotifier<LibrarySyncStatus> _syncStatus =
      ValueNotifier(LibrarySyncStatus());

  bool _isSyncCancelled = false;

  void cancelSync() {
    _isSyncCancelled = true;
    resetInitialSyncTask();
    _syncStatus.value = _syncStatus.value
        .copyWith(isSyncing: false, clearError: true, clearInfo: true);
  }

  LibraryService({required ProfileAuthService auth, db.AppDatabase? database})
      : _auth = auth,
        _db = database ?? getIt<db.AppDatabase>();

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

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Future<FetchPageResult> _fetchPage(
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

    final uri = Uri.parse(LibraryConstants.baseUrl).replace(queryParameters: queryParams);
    _logger.info('Fetching library page $page. URL: $uri');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': LibraryConstants.userAgent,
      }).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('Library page $page fetch completed with status ${response.statusCode}');

      if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching library page $page. Retrying in ${AppConstants.rateLimitRetryDelaySeconds}s...');
        await Future.delayed(Duration(seconds: AppConstants.rateLimitRetryDelaySeconds));
        return _fetchPage(token, page, state: state, sortBy: sortBy);
      }

      if (response.statusCode == 401) {
        _logger.severe('Unauthorized fetch request for library page $page');
        throw AuthException(message: 'Auth failed', code: 'AUTH_FAILED');
      }
      if (response.statusCode == 400) {
        _logger.warning('Bad request for library page $page: ${response.body}');
        return FetchPageResult(entries: [], totalEntries: 0, isError: true);
      }
      if (response.statusCode != 200) {
        _logger.severe('Failed to fetch library page $page. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiException(message: 'Fetch failed', statusCode: response.statusCode);
      }

      final result = await compute(_parseLibraryPage, response.body);
      _logger.info('Successfully parsed ${result.entries.length} entries for library page $page');
      return result;
    } catch (e, st) {
      _logger.severe('Exception occurred while fetching library page $page: $e\n$st');
      rethrow;
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
    await _db.libraryEntriesDao.upsertLibraryEntries(entries);
  }

  DateTime? _parseAsUtc(String dateStr) {
    if (dateStr.isEmpty) return null;
    final numValue = int.tryParse(dateStr);
    if (numValue != null) {
      if (dateStr.length == 10) return DateTime.fromMillisecondsSinceEpoch(numValue * 1000, isUtc: true);
      if (dateStr.length == 13) return DateTime.fromMillisecondsSinceEpoch(numValue, isUtc: true);
    }
    return DateTime.tryParse(dateStr)?.toUtc();
  }
}

class FetchPageResult {
  final List<api.LibraryEntry> entries;
  final int totalEntries;
  final bool isError;
  FetchPageResult({required this.entries, required this.totalEntries, this.isError = false});
}

FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody) as Map<String, dynamic>;
  final data = (body['data'] as List<dynamic>? ?? const []);
  final entries = data.map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>)).toList();
  return FetchPageResult(entries: entries, totalEntries: 0);
}
