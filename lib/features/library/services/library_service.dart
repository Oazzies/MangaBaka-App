import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';
import 'package:bakahyou/utils/services/logging_service.dart';

class LibraryService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  final db.AppDatabase _db;
  bool _hasPerformedInitialSync = false;

  LibraryService._({ProfileAuthService? auth})
    : _auth = auth ?? ProfileAuthService(),
      _db = db.AppDatabase();

  static final LibraryService _instance = LibraryService._();

  factory LibraryService({ProfileAuthService? auth}) {
    return _instance;
  }

  /// Watches a single library entry by series ID.
  Stream<api.LibraryEntry?> watchEntryFromDb(String seriesId) {
    try {
      return _db.libraryEntriesDao
          .watchEntryWithSeries(seriesId)
          .map(
            (dbEntry) => dbEntry != null
                ? DbToApiMapper.libraryEntryFromDb(dbEntry)
                : null,
          );
    } catch (e) {
      _logger.severe('Failed to watch entry from db: $e');
      throw Exception('Failed to watch entry from db.');
    }
  }

  Stream<List<api.LibraryEntry>> watchEntriesFromDb() {
    try {
      return _db.libraryEntriesDao.watchAllEntriesWithSeries().map(
        (dbEntries) => dbEntries.map(DbToApiMapper.libraryEntryFromDb).toList(),
      );
    } catch (e) {
      _logger.severe('Failed to watch entries from db: $e');
      throw Exception('Failed to watch entries from db.');
    }
  }

  /// Performs initial sync only once on first app load.
  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    _hasPerformedInitialSync = true;
    try {
      await syncLibrary();
    } catch (e) {
      _logger.severe('Failed to perform initial sync: $e');
      throw Exception('Failed to perform initial sync.');
    }
  }

  /// Performs a full sync with the remote API.
  Future<void> syncLibrary() async {
    try {
      final token = await _auth.getValidAccessToken();
      if (token == null) return;

      var page = 1;
      while (true) {
        final entries = await _fetchPage(token, page);
        await _saveEntries(entries);
        if (entries.length < LibraryConstants.pageLimit) {
          break;
        }
        page++;
      }
    } catch (e) {
      _logger.severe('Failed to sync library: $e');
      throw Exception('Failed to sync library.');
    }
  }

  Future<List<api.LibraryEntry>> _fetchPage(String token, int page) async {
    final uri = Uri.parse(
      '${LibraryConstants.baseUrl}?page=$page&limit=${LibraryConstants.pageLimit}',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': LibraryConstants.userAgent,
        },
      );

      if (response.statusCode == 429) {
        _logger.warning('Rate limited while fetching library page. Retrying...');
        await Future.delayed(const Duration(seconds: 2));
        return _fetchPage(token, page);
      }
      if (response.statusCode != 200) {
        _logger.severe(
            'Library sync failed: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load library page: ${response.statusCode}');
      }

      final data =
          (jsonDecode(response.body)['data'] as List<dynamic>? ?? const []);
      final entries = data
          .map((item) =>
              api.LibraryEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      return entries;
    } catch (e) {
      _logger.severe('Failed to fetch library page: $e');
      throw Exception('Failed to fetch library page.');
    }
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    try {
      await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
      await _db.libraryEntriesDao.upsertLibraryEntries(entries);
    } catch (e) {
      _logger.severe('Failed to save entries: $e');
      throw Exception('Failed to save entries.');
    }
  }

  Future<void> updateLibraryEntryState(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': LibraryConstants.userAgent,
      },
      body: jsonEncode({'state': state}),
    );

    print("!!! UPDATE STATE LIBRARY API CALL MADE!!!");

    if (response.statusCode != 200) {
      throw Exception('Failed to update library entry state: ${response.body}');
    }

    // Update the local database entry directly instead of a full sync
    await _db.libraryEntriesDao.updateEntryState(seriesId, state);
  }

  Future<void> updateLibraryEntryRating(String seriesId, int rating) async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    final url = Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': LibraryConstants.userAgent,
      },
      body: jsonEncode({'rating': rating}),
    );

    print("!!! UPDATE RATING LIBRARY API CALL MADE!!!");

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update library entry rating: ${response.body}',
      );
    }

    await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
  }

    Future<void> createLibraryEntry(String seriesId, String state) async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    final url =
        Uri.parse('${LibraryConstants.baseUrl}/$seriesId');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': LibraryConstants.userAgent,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'state': state}),
    );

    print("!!! CREATE LIBRARY API CALL MADE!!!");

    if (response.statusCode == 201) {
      await syncLibrary();
    } else {
      throw Exception('Failed to create library entry: ${response.body}');
    }
  }

    /// Deletes a library entry by series ID from both the API and local DB.
  Future<void> deleteEntry(String seriesId) async {
    final token = await _auth.getValidAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = '${LibraryConstants.baseUrl}/$seriesId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': LibraryConstants.userAgent,
      },
    );
    
    print("!!! DELETE LIBRARY API CALL MADE!!!");

    if (response.statusCode == 200 || response.statusCode == 404) {
      // Also delete from local DB
      await _db.libraryEntriesDao.deleteEntry(seriesId);
    } else {
      // Handle other status codes, like 401, 403, etc.
      throw Exception('Failed to delete library entry: ${response.body}');
    }
  }
}
