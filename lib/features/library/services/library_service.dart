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

  LibraryService({ProfileAuthService? auth})
      : _auth = auth ?? ProfileAuthService(),
        _db = db.AppDatabase.instance;

  // Load library entries from the local database
  Future<List<api.LibraryEntry>> getEntriesFromDb() async {
    final dbEntries = await _db.libraryEntriesDao.getAllEntriesWithSeries();
    return dbEntries
        .map(DbToApiMapper.libraryEntryFromDb)
        .toList();
  }

  // Fetch all library entries from the API and save them to the database
  Future<List<api.LibraryEntry>> fetchAllEntriesAndSave() async {
    final token = await _auth.getValidAccessToken();
    final allEntries = <api.LibraryEntry>[];
    var page = 1;

    while (true) {
      final entries = await _fetchPage(token, page);
      
      if (entries.isEmpty) {
        break;
      }

      allEntries.addAll(entries);
      
      // Save to database after each page
      await _saveEntries(entries);
      
      page++;
    }

    return allEntries;
  }

  // Fetch a single page from the API
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

    print("!!! LIBRARY API CALL MADE!!!");

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch library page $page: ${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>? ?? const []);
    final pagination = body['pagination'] as Map<String, dynamic>?;
    final hasNext = pagination != null && pagination['next'] != null;

    if (!hasNext) {
      // Mark this as the last page by returning empty
      return data
          .map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return data
        .map((item) => api.LibraryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Save library entries to the database
  Future<void> _saveEntries(List<api.LibraryEntry> entries) async {
    if (entries.isEmpty) return;
    
    await _db.seriesDao.upsertSeries(entries.map((e) => e.series).toList());
    await _db.libraryEntriesDao.upsertLibraryEntries(entries);
  }
}