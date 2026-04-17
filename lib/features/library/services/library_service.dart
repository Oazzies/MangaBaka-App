import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bakahyou/database/database.dart' as db;
import 'package:bakahyou/features/library/models/library_entry.dart' as api;
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/library/services/mappers/db_to_api_mapper.dart';

class LibraryService {
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
    return _db.libraryEntriesDao
        .watchEntryWithSeries(seriesId)
        .map((dbEntry) => dbEntry != null ? DbToApiMapper.libraryEntryFromDb(dbEntry) : null);
  }

  Stream<List<api.LibraryEntry>> watchEntriesFromDb() {
    return _db.libraryEntriesDao.watchAllEntriesWithSeries().map(
      (dbEntries) => dbEntries.map(DbToApiMapper.libraryEntryFromDb).toList(),
    );
  }

  /// Performs initial sync only once on first app load.
  Future<void> performInitialSyncIfNeeded() async {
    if (_hasPerformedInitialSync) return;
    _hasPerformedInitialSync = true;
    await syncLibrary();
  }

  /// Performs a full sync with the remote API.
  Future<void> syncLibrary() async {
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
  }

  Future<List<api.LibraryEntry>> _fetchPage(String token, int page) async {
    final uri = Uri.parse(
      '${LibraryConstants.baseUrl}?page=$page&limit=${LibraryConstants.pageLimit}',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': LibraryConstants.userAgent,
      },
    );

    print("!!! LIBRARY API CALL MADE (page $page)!!!");

    if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 2));
      return _fetchPage(token, page);
    }
    if (response.statusCode != 200) {
      print('Library sync failed: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load library page');
    }

    final data =
        (jsonDecode(response.body)['data'] as List<dynamic>? ?? const []);
    final entries = data
        .map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    return entries;
  }

  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
    await _db.libraryEntriesDao.upsertLibraryEntries(entries);
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

    print("!!! UPDATE LIBRARY API CALL MADE!!!");

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

    if (response.statusCode != 200) {
      throw Exception('Failed to update library entry rating: ${response.body}');
    }

    await _db.libraryEntriesDao.updateEntryRating(seriesId, rating);
  }
}