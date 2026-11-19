import 'dart:convert';
import 'dart:async';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/constants/library_constants.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:http/http.dart' as http;

class SnapshotService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;

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

  static Future<void>? _requestLock;

  static DateTime? _lastRelease;
  static const _cooldown = Duration(milliseconds: 300);

  Future<List<LibraryEntry>> fetchSnapshot({
    required String sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final previousLock = _requestLock;
    final completer = Completer<void>();
    _requestLock = completer.future;

    if (previousLock != null) {
      await previousLock;
      final released = _lastRelease;
      if (released != null) {
        final remaining = _cooldown - DateTime.now().difference(released);
        if (remaining > Duration.zero) await Future.delayed(remaining);
      }
    }

    try {
      final contentPrefs = SettingsManager().contentPreferences;
      var urlStr =
          '${LibraryConstants.baseUrl}?page=$page&limit=$limit&sort_by=$sortBy';
      for (final pref in contentPrefs) {
        urlStr += '&content_rating=$pref';
      }
      final uri = Uri.parse(urlStr);

      final response = await _auth.sendAuthorized(
        (token) => http
            .get(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'User-Agent': LibraryConstants.userAgent,
              },
            )
            .timeout(
              Duration(seconds: AppConstants.networkTimeoutSeconds),
              onTimeout: () =>
                  throw TimeoutException('Snapshot fetch timed out'),
            ),
      );

      _logger.fine('Snapshot fetch completed (sortBy: $sortBy, page: $page)');

      reportApiOutcome(
        ok: !isServerErrorStatus(response.statusCode),
        context: 'library-snapshot',
        statusCode: response.statusCode,
      );

      if (response.statusCode != 200) {
        _logger.severe(
          'Failed to fetch library snapshot: ${response.statusCode}',
        );
        throw ApiException(
          message: 'Failed to fetch library snapshot',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body);
      final data = body is Map && body['data'] is List
          ? body['data'] as List
          : const [];
      final results = <LibraryEntry>[];
      for (final item in data) {
        try {
          if (item is Map) {
            results.add(LibraryEntry.fromJson(item.cast<String, dynamic>()));
          }
        } catch (e) {
          _logger.fine('Skipping malformed snapshot entry: $e');
        }
      }

      if (contentPrefs.isNotEmpty) {
        return results
            .where(
              (e) =>
                  contentPrefs.contains(e.series.contentRating.toLowerCase()),
            )
            .toList();
      }
      return results;
    } on AppException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to fetch library snapshot', e, st);
      reportApiOutcome(ok: false, context: 'library-snapshot', error: e);
      throw NetworkException(
        message: 'Failed to fetch library snapshot',
        originalError: e,
        stackTrace: st,
      );
    } finally {
      _lastRelease = DateTime.now();
      completer.complete();
    }
  }
}
