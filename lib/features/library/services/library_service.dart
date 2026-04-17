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

  /// Watches for changes in the local database and provides a stream of entries.
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

    var page = 1;
    while (true) {
      final remoteEntries = await _fetchPage(token, page);
      if (remoteEntries.isEmpty) {
        break; // No more pages
      }

      await _saveEntries(remoteEntries);

      // If a page has fewer items than the limit, it must be the last one.
      if (remoteEntries.length < LibraryConstants.pageLimit) {
        break;
      }

      page++;

      // Add delay between requests to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<List<api.LibraryEntry>> _fetchPage(String token, int page) async {
    final uri = Uri.parse(
      '${LibraryConstants.baseUrl}?page=$page&limit=${LibraryConstants.pageLimit}&sort_by=updated_at_desc',
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
      throw Exception('Rate limited. Please try again later.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch library page $page: ${response.statusCode}',
      );
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
}
