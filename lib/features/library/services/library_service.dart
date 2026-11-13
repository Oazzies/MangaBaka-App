import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/database/database.dart' as db;
import 'package:mangabaka_app/features/library/models/library_entry.dart'
    as api;
import 'package:mangabaka_app/features/series/models/series.dart' as api_series;
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_crud_mixin.dart';
import 'package:mangabaka_app/features/library/services/mixins/library_sync_mixin.dart';

import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';

part 'library_service_remote.dart';

abstract class LibraryServiceBase {
  db.AppDatabase get database;
  ProfileAuthService get auth;
  dynamic get logger;

  ValueNotifier<LibrarySyncStatus> get syncStatus;
  bool get isSyncCancelled;
  void setIsSyncCancelled(bool val);

  Future<void> syncLibrary({String? state, bool deep = false});
  Future<FetchPageResult> fetchPage(
    int page, {
    String? state,
    String? type,
    String? sortBy,
  });
  Future<LibraryChangesPage> fetchChanges(String? cursor);
  Future<List<api_series.Series>> fetchSeriesBatch(List<String> ids);
  Future<void> saveEntries(List<api.LibraryEntry> entries);
  DateTime? parseAsUtc(String dateStr);

  void resetInitialSyncTask();
}

class LibraryService extends LibraryServiceBase
    with LibraryCrudMixin, LibrarySyncMixin {
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
  Future<FetchPageResult> fetchPage(
    int page, {
    String? state,
    String? type,
    String? sortBy,
  }) => _fetchPage(page, state: state, type: type, sortBy: sortBy);

  @override
  Future<LibraryChangesPage> fetchChanges(String? cursor) =>
      _fetchChanges(cursor);

  @override
  Future<List<api_series.Series>> fetchSeriesBatch(List<String> ids) =>
      _fetchSeriesBatch(ids);

  @override
  Future<void> saveEntries(List<api.LibraryEntry> entries) =>
      _saveEntries(entries);

  @override
  DateTime? parseAsUtc(String dateStr) => _parseAsUtc(dateStr);

  final ValueNotifier<LibrarySyncStatus> _syncStatus = ValueNotifier(
    LibrarySyncStatus(),
  );

  bool _isSyncCancelled = false;

  void cancelSync() {
    _isSyncCancelled = true;
    resetInitialSyncTask();
    _syncStatus.value = _syncStatus.value.copyWith(
      isSyncing: false,
      clearError: true,
      clearInfo: true,
    );
  }

  LibraryService({required ProfileAuthService auth, db.AppDatabase? database})
    : _auth = auth,
      _db = database ?? getIt<db.AppDatabase>();

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

  /// How many times a rate-limited (429) page fetch is retried before giving
  /// up. Without a cap, a persistently rate-limited sync would retry forever.
  static const int _maxRateLimitRetries = 3;

  Future<FetchPageResult> _fetchPage(
    int page, {
    String? state,
    String? type,
    String? sortBy,
    int retryCount = 0,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': LibraryConstants.pageLimit.toString(),
    };
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final uri = Uri.parse(
      LibraryConstants.baseUrl,
    ).replace(queryParameters: queryParams);
    _logger.info('Fetching library page $page. URL: $uri');

    try {
      // A 401 is recovered from (or becomes SessionExpiredException) here.
      final response = await _auth.sendAuthorized(
        (token) => http
            .get(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'User-Agent': LibraryConstants.userAgent,
              },
            )
            .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds)),
      );

      _logger.fine(
        'Library page $page fetch completed with status ${response.statusCode}',
      );

      if (response.statusCode == 429) {
        if (retryCount >= _maxRateLimitRetries) {
          _logger.severe(
            'Rate limited while fetching library page $page after $_maxRateLimitRetries retries. Giving up.',
          );
          throw ApiException(
            message: 'Rate limited by server',
            statusCode: response.statusCode,
            code: 'RATE_LIMITED',
          );
        }
        _logger.warning(
          'Rate limited while fetching library page $page. Retrying in ${AppConstants.rateLimitRetryDelaySeconds}s...',
        );
        await Future.delayed(
          Duration(seconds: AppConstants.rateLimitRetryDelaySeconds),
        );
        return await _fetchPage(
          page,
          state: state,
          type: type,
          sortBy: sortBy,
          retryCount: retryCount + 1,
        );
      }

      if (response.statusCode == 400) {
        _logger.warning('Bad request for library page $page');
        return FetchPageResult(entries: [], isError: true);
      }
      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to fetch library page $page. Status: ${response.statusCode}',
        );
        throw ApiException(
          message: 'Fetch failed',
          statusCode: response.statusCode,
        );
      }

      final result = await compute(_parseLibraryPage, response.body);
      _logger.info(
        'Successfully parsed ${result.entries.length} entries for library page $page',
      );
      return result;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e, st) {
      // Mapped like every other library call, so callers that catch
      // NetworkException (the initial sync, the retry banner) see it.
      _logger.severe('Timed out fetching library page $page', e, st);
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      _logger.severe('Network error fetching library page $page', e, st);
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      _logger.severe('Network error fetching library page $page', e, st);
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on FormatException catch (e, st) {
      throw _pageParseFailure(page, e, st);
    } on TypeError catch (e, st) {
      // A field of an unexpected type in the payload, not a bug in this
      // client: the server shape drifted.
      throw _pageParseFailure(page, e, st);
    }
  }

  ParseException _pageParseFailure(int page, Object e, StackTrace st) {
    _logger.severe('Failed to parse library page $page', e, st);
    return ParseException(
      message: 'Failed to parse library page $page',
      originalError: e,
      stackTrace: st,
    );
  }

  /// Largest page the feed allows; a full scan of 15,000 series is 15 calls.
  static const int _changesLimit = 1000;

  /// One page of `GET /v2/my/library/changes`.
  Future<LibraryChangesPage> _fetchChanges(
    String? cursor, {
    int retryCount = 0,
  }) => _fetchChangesImpl(this, cursor, retryCount: retryCount);

  /// Catalog data for [ids] from `GET /v1/series/batch`, 50 per request.
  ///
  /// v1, not v2: only v1 carries the server's canonical `title` /
  /// `native_title` / `romanized_title` (v2 has just the per-language list, so
  /// the title would have to be guessed and then disagree with the detail
  /// page), and the genres, tags, year and links the library filters on.
  Future<List<api_series.Series>> _fetchSeriesBatch(List<String> ids) =>
      _fetchSeriesBatchImpl(this, ids);

  Future<void> _saveEntries(List<api.LibraryEntry> entries) =>
      _saveEntriesImpl(this, entries);

  DateTime? _parseAsUtc(String dateStr) => _parseAsUtcImpl(dateStr);
}
