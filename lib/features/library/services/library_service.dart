import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;

  LibraryService({required ProfileAuthService auth})
    : _auth = auth,
      _db = db.AppDatabase();

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
          return [];
        }, test: (error) => true);
  }

  /// Performs initial sync only once on first app load.
  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    _hasPerformedInitialSync = true;
    try {
      await syncLibrary();
    } catch (e, st) {
      _logger.severe('Failed to perform initial sync: $e\n$st');
      _hasPerformedInitialSync = false;
      rethrow;
    }
  }

  /// Performs a full sync with the remote API.
  Future<void> syncLibrary() async {
    try {
      final token = await _auth.getValidAccessToken();

      var page = 1;
      while (true) {
        final entries = await _fetchPage(token, page);
        await _saveEntries(entries);
        if (entries.length < LibraryConstants.pageLimit) {
          break;
        }
        page++;
      }
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } on DatabaseException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to sync library: $e\n$st');
      throw AppError(
        message: 'Failed to sync library',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<List<api.LibraryEntry>> _fetchPage(String token, int page) async {
    final uri = Uri.parse(
      '${LibraryConstants.baseUrl}?page=$page&limit=${LibraryConstants.pageLimit}',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () => throw TimeoutException('Library fetch timed out'),
          );

      print("Library API");

      if (response.statusCode == 429) {
        _logger.warning(
          'Rate limited fetching library page $page. Retrying after delay...',
        );
        await Future.delayed(
          Duration(seconds: AppConstants.rateLimitRetryDelaySeconds),
        );
        return _fetchPage(token, page);
      }

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',

          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to fetch library page. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to fetch library page',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'FETCH_PAGE_FAILED',
        );
      }

      try {
        final data =
            (jsonDecode(response.body)['data'] as List<dynamic>? ?? const []);
        return data
            .map(
              (item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } catch (e, st) {
        _logger.severe('Failed to parse library page: $e\n$st');
        throw ParseException(
          message: 'Failed to parse library page',
          originalError: e,
          stackTrace: st,
        );
      }
    } on SocketException catch (e, st) {
      _logger.severe('Network error fetching library page: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout fetching library page: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on ParseException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error fetching library page: $e\n$st');
      throw AppError(
        message: 'Unexpected error fetching library page',
        originalError: e,
        stackTrace: st,
      );
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

      print("Update Library API");

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to update entry state. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to update entry state',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_STATE_FAILED',
        );
      }

      // Update the local database entry
      await _db.libraryEntriesDao.updateEntryState(seriesId, state);
    } on SocketException catch (e, st) {
      _logger.severe('Network error updating entry state: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout updating entry state: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry state: $e\n$st');
      throw AppError(
        message: 'Failed to update entry state',
        originalError: e,
        stackTrace: st,
      );
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
      
      print("Library Rating API");

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to update entry rating. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to update entry rating',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'UPDATE_RATING_FAILED',
        );
      }

      await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
    } on SocketException catch (e, st) {
      _logger.severe('Network error updating entry rating: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout updating entry rating: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error updating entry rating: $e\n$st');
      throw AppError(
        message: 'Failed to update entry rating',
        originalError: e,
        stackTrace: st,
      );
    }
  }

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
      
      print("Create Library API");

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode == 201) {
        await syncLibrary();
      } else {
        _logger.severe(
          'Failed to create library entry. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to create library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'CREATE_ENTRY_FAILED',
        );
      }
    } on SocketException catch (e, st) {
      _logger.severe('Network error creating entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout creating entry: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error creating entry: $e\n$st');
      throw AppError(
        message: 'Failed to create library entry',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  Future<void> deleteEntry(String seriesId) async {
    final token = await _auth.getValidAccessToken();

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'User-Agent': LibraryConstants.userAgent,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.networkTimeoutSeconds),
            onTimeout: () =>
                throw TimeoutException('Delete entry request timed out'),
          );

      print("Delete Library API");

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Authentication failed. Please log in again.',
          code: 'AUTH_FAILED',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 404) {
        // Also delete from local DB
        await _db.libraryEntriesDao.deleteEntry(seriesId);
      } else {
        _logger.severe(
          'Failed to delete entry. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw ApiException(
          message: 'Failed to delete library entry',
          statusCode: response.statusCode,
          responseBody: response.body,
          code: 'DELETE_ENTRY_FAILED',
        );
      }
    } on SocketException catch (e, st) {
      _logger.severe('Network error deleting entry: $e\n$st');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        code: 'NETWORK_ERROR',
        originalError: e,
        stackTrace: st,
      );
    } on TimeoutException catch (e, st) {
      _logger.severe('Request timeout deleting entry: $e\n$st');
      throw NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: e,
        stackTrace: st,
      );
    } on AuthException {
      rethrow;
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Unexpected error deleting entry: $e\n$st');
      throw AppError(
        message: 'Failed to delete library entry',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
