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
    } catch (e, st) {
      _logger.severe(
        'Exception occurred while fetching library page $page: $e\n$st',
      );
      if (e is FormatException || e is TypeError) {
        throw ParseException(
          message: 'Failed to parse library page $page',
          originalError: e,
          stackTrace: st,
        );
      }
      rethrow;
    }
  }

  /// Largest page the feed allows; a full scan of 15,000 series is 15 calls.
  static const int _changesLimit = 1000;

  /// One page of `GET /v2/my/library/changes`.
  Future<LibraryChangesPage> _fetchChanges(
    String? cursor, {
    int retryCount = 0,
  }) async {
    final uri = Uri.parse('${AppConstants.baseApiUrlV2}/my/library/changes')
        .replace(
          queryParameters: {
            'limit': '$_changesLimit',
            if (cursor != null) 'cursor': cursor,
          },
        );
    _logger.info('Fetching library changes. URL: $uri');

    try {
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

      if (response.statusCode == 429) {
        if (retryCount >= _maxRateLimitRetries) {
          throw ApiException(
            message: 'Rate limited by server',
            statusCode: response.statusCode,
            code: 'RATE_LIMITED',
          );
        }
        final wait =
            int.tryParse(response.headers['retry-after'] ?? '') ??
            AppConstants.rateLimitRetryDelaySeconds;
        await Future.delayed(Duration(seconds: wait.clamp(1, 60)));
        return _fetchChanges(cursor, retryCount: retryCount + 1);
      }
      if (response.statusCode == 400) {
        return const LibraryChangesPage(invalidCursor: true);
      }
      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Fetch failed',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body);
      final data = body is Map ? body['data'] : null;
      final pagination = body is Map ? body['pagination'] : null;
      if (data is! List) {
        throw ParseException(message: 'Library changes had no data list');
      }
      return LibraryChangesPage(
        items: [
          for (final item in data)
            if (item is Map) item.cast<String, dynamic>(),
        ],
        cursor: pagination is Map ? pagination['cursor']?.toString() : null,
        more: pagination is Map && pagination['more'] == true,
      );
    } on AppException {
      rethrow;
    } on TimeoutException catch (e, st) {
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on FormatException catch (e, st) {
      throw ParseException(
        message: 'Failed to parse library changes',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Catalog data for [ids] from `GET /v2/series/batch`, 50 per request.
  Future<List<api_series.Series>> _fetchSeriesBatch(List<String> ids) async {
    final result = <api_series.Series>[];
    for (var i = 0; i < ids.length; i += 50) {
      if (i > 0) {
        // A full scan of a big library is hundreds of these; spread them out
        // rather than trip the rate limit.
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      final chunk = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
      result.addAll(await _fetchSeriesChunk(chunk));
    }
    return result;
  }

  /// One `GET /v2/series/batch` of at most 50 ids.
  ///
  /// Rate limits and server errors are retried with backoff (honouring
  /// `Retry-After`). A chunk the server refuses outright (one bad id fails the
  /// whole request) is split in halves until the offending id is isolated and
  /// skipped, so one series cannot sink the sync of a 14,000-series library.
  Future<List<api_series.Series>> _fetchSeriesChunk(
    List<String> chunk, {
    int attempt = 0,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseApiUrlV2}/series/batch',
    ).replace(queryParameters: {'id': chunk});
    try {
      final response = await http
          .get(uri, headers: {'User-Agent': LibraryConstants.userAgent})
          .timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));
      final status = response.statusCode;

      if (status == 429 || status >= 500) {
        if (attempt >= 5) {
          throw ApiException(
            message: 'Series batch failed ($status)',
            statusCode: status,
          );
        }
        final wait =
            int.tryParse(response.headers['retry-after'] ?? '') ??
            (2 << attempt);
        _logger.warning(
          'Series batch got $status; retrying in ${wait}s (attempt ${attempt + 1}).',
        );
        await Future<void>.delayed(Duration(seconds: wait.clamp(1, 60)));
        return _fetchSeriesChunk(chunk, attempt: attempt + 1);
      }

      if (status != 200) {
        _logger.warning(
          'Series batch got $status for ${chunk.length} ids: ${response.body}',
        );
        if (chunk.length == 1) return const [];
        final mid = chunk.length ~/ 2;
        return [
          ...await _fetchSeriesChunk(chunk.sublist(0, mid)),
          ...await _fetchSeriesChunk(chunk.sublist(mid)),
        ];
      }

      final data = (jsonDecode(response.body) as Map)['data'];
      final found = <api_series.Series>[];
      if (data is List) {
        for (final item in data) {
          try {
            found.add(
              api_series.Series.fromJson((item as Map).cast<String, dynamic>()),
            );
          } catch (_) {
            // One bad series costs that series, not the page.
          }
        }
      }
      return found;
    } on AppException {
      rethrow;
    } on TimeoutException catch (e, st) {
      throw NetworkException(
        message: 'Request timed out.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw NetworkException(
        message: 'Network error.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    // One transaction: a failure on the entries leaves no half-written page
    // (series rows without their library entries) behind.
    await _db.transaction(() async {
      await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
      await _db.libraryEntriesDao.upsertLibraryEntries(entries);
    });
  }

  DateTime? _parseAsUtc(String dateStr) {
    if (dateStr.isEmpty) return null;
    final numValue = int.tryParse(dateStr);
    if (numValue != null) {
      if (dateStr.length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(numValue * 1000, isUtc: true);
      }
      if (dateStr.length == 13) {
        return DateTime.fromMillisecondsSinceEpoch(numValue, isUtc: true);
      }
    }
    return DateTime.tryParse(dateStr)?.toUtc();
  }
}

/// One page of the library change feed.
class LibraryChangesPage {
  final List<Map<String, dynamic>> items;

  /// Opaque position to send back for the next page; save it once applied.
  final String? cursor;
  final bool more;

  /// The server refused the cursor (or request): scan from the start.
  final bool invalidCursor;

  const LibraryChangesPage({
    this.items = const [],
    this.cursor,
    this.more = false,
    this.invalidCursor = false,
  });
}

class FetchPageResult {
  final List<api.LibraryEntry> entries;
  final bool isError;

  /// Entries on the page that could not be parsed and were left out. When
  /// non-zero the page is not a complete picture of the server's library.
  final int skipped;
  FetchPageResult({
    required this.entries,
    this.isError = false,
    this.skipped = 0,
  });
}

FetchPageResult _parseLibraryPage(String responseBody) {
  final body = jsonDecode(responseBody);
  final data = body is Map ? body['data'] : null;
  if (data is! List) return FetchPageResult(entries: []);
  // One malformed entry must cost that entry, not the page: a throw here
  // fails the whole sync, and it would fail identically on every retry.
  final entries = <api.LibraryEntry>[];
  var skipped = 0;
  for (final item in data) {
    try {
      entries.add(api.LibraryEntry.fromJson(item as Map<String, dynamic>));
    } catch (_) {
      skipped++;
    }
  }
  return FetchPageResult(entries: entries, skipped: skipped);
}
