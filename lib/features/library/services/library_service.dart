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

part 'library_service_sync_full.dart';
part 'library_service_sync_recent.dart';
part 'library_service_crud.dart';
part 'library_service_api.dart';

// ─── Prefs keys ───────────────────────────────────────────────────────────
const String _lastSyncKey = AppConstants.lastSyncKey;
const String _isIncompleteKey =
    '${AppConstants.prefixStorageKey}library_is_incomplete';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;

  // ─── Sync state notifier ──────────────────────────────────────────────────
  final ValueNotifier<LibrarySyncStatus> syncStatus =
      ValueNotifier(LibrarySyncStatus());

  bool _isSyncCancelled = false;
  Future<void>? _initialSyncTask;

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
}
