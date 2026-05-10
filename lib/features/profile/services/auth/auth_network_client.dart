import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class AuthNetworkClient {
  final _logger = LoggingService.logger;
  static const _meEndpoint = '${AppConstants.baseApiUrl}/me';
  static const _userInfoEndpoint = '${AppConstants.authBaseUrl}/userinfo';

  Future<MbProfile> fetchProfile(String accessToken) async {
    _logger.info('Fetching profile from API. Endpoint: $_meEndpoint');
    try {
      final res = await http.get(
        Uri.parse(_meEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': AppConstants.userAgent,
        },
      ).timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('Profile fetch (me) status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _logger.info('Successfully fetched profile from /me');
        return MbProfile.fromMeResponse(body);
      } else if (res.statusCode == 404) {
        _logger.warning('Profile not found at /me. Falling back to /userinfo. Endpoint: $_userInfoEndpoint');
        final userinfoRes = await http.get(
          Uri.parse(_userInfoEndpoint),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': AppConstants.userAgent,
          },
        ).timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

        _logger.fine('Profile fetch (userinfo) status: ${userinfoRes.statusCode}');

        if (userinfoRes.statusCode == 200) {
          final body = jsonDecode(userinfoRes.body) as Map<String, dynamic>;
          _logger.info('Successfully fetched profile from /userinfo');
          return MbProfile.fromUserInfo(body);
        } else {
          _logger.severe('Failed to fetch profile from /userinfo. Status: ${userinfoRes.statusCode}, Body: ${userinfoRes.body}');
          throw AuthException(message: 'Failed to fetch profile from userinfo', code: '${userinfoRes.statusCode}');
        }
      } else {
        _logger.severe('Failed to fetch profile from /me. Status: ${res.statusCode}, Body: ${res.body}');
        throw AuthException(message: 'Failed to fetch profile from me', code: '${res.statusCode}');
      }
    } catch (e, st) {
      _logger.severe('Network error during profile fetch: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Network fetch profile failed', originalError: e, stackTrace: st);
    }
  }
}
