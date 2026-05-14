import 'dart:convert';
import 'dart:async';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_constants.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:http/http.dart' as http;

class SnapshotService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;
  
  // Simple in-memory cache for the "Activity" list
  List<LibraryEntry>? _cachedActivities;
  List<LibraryEntry>? get cachedActivities => _cachedActivities;

  SnapshotService({ProfileAuthService? auth})
    : _auth = auth ?? getIt<ProfileAuthService>();

  void setCachedActivities(List<LibraryEntry> activities) {
    _cachedActivities = activities;
  }

  void clearCache() {
    _cachedActivities = null;
  }

  // Lock to prevent concurrent requests to the same endpoint
  static Future<void>? _requestLock;

  Future<List<LibraryEntry>> fetchSnapshot({
    required String sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    // Wait for the previous request to finish
    final previousLock = _requestLock;
    final completer = Completer<void>();
    _requestLock = completer.future;

    if (previousLock != null) {
      await previousLock;
      // Add a small cool-down delay between requests to be safe
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      final token = await _auth.getValidAccessToken();
      final contentPrefs = SettingsManager().contentPreferences;
      var urlStr = '${LibraryConstants.baseUrl}?page=$page&limit=$limit&sort_by=$sortBy';
      for (final pref in contentPrefs) {
        urlStr += '&content_rating=$pref';
      }
      final uri = Uri.parse(urlStr);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': LibraryConstants.userAgent,
        },
      ).timeout(
        Duration(seconds: AppConstants.networkTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Snapshot fetch timed out'),
      );

      _logger.fine('Snapshot fetch completed (sortBy: $sortBy, page: $page)');

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to fetch library snapshot: ${response.statusCode} ${response.body}',
        );
        throw ApiException(
          message: 'Failed to fetch library snapshot',
          statusCode: response.statusCode,
        );
      }

      final data = (jsonDecode(response.body)['data'] as List<dynamic>? ?? []);
      final results = data.map((item) => LibraryEntry.fromJson(item)).toList();
      
      if (contentPrefs.isNotEmpty) {
        return results.where((e) => contentPrefs.contains(e.series.contentRating.toLowerCase())).toList();
      }
      return results;
    } on AppException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to fetch library snapshot: $e\n$st');
      throw NetworkException(
        message: 'Failed to fetch library snapshot',
        originalError: e,
        stackTrace: st,
      );
    } finally {
      completer.complete();
    }
  }
}
