import 'dart:convert';
import 'dart:async';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_constants.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:http/http.dart' as http;

class SnapshotService {
  final _logger = LoggingService.logger;
  final ProfileAuthService _auth;

  SnapshotService({ProfileAuthService? auth})
    : _auth = auth ?? getIt<ProfileAuthService>();

  Future<List<LibraryEntry>> fetchSnapshot({
    required String sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _auth.getValidAccessToken();
      final uri = Uri.parse(
        '${LibraryConstants.baseUrl}?page=$page&limit=$limit&sort_by=$sortBy',
      );

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
      return data.map((item) => LibraryEntry.fromJson(item)).toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      _logger.severe('Failed to fetch library snapshot: $e\n$st');
      throw NetworkException(
        message: 'Failed to fetch library snapshot',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
