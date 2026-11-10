import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';

class AuthNetworkClient {
  final _logger = LoggingService.logger;
  static const _meEndpoint = '${AppConstants.baseApiUrl}/my/profile';
  static const _userInfoEndpoint = '${AppConstants.authBaseUrl}/userinfo';

  Future<MbProfile> fetchProfile(String accessToken) async {
    _logger.info('Fetching profile from API...');
    try {
      MbProfile? meProfile;
      MbProfile? userInfoProfile;
      Object? lastError;

      // 1. Fetch userinfo from OIDC endpoint
      try {
        final res = await http
            .get(
              Uri.parse(_userInfoEndpoint),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'User-Agent': AppConstants.userAgent,
              },
            )
            .timeout(
              const Duration(seconds: AppConstants.networkTimeoutSeconds),
            );

        _logger.fine('Profile fetch (userinfo) status: ${res.statusCode}');
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          userInfoProfile = MbProfile.fromUserInfo(body);
        }
      } catch (e) {
        lastError = e;
        _logger.warning('Failed to fetch from /userinfo: $e');
      }

      // 2. Fetch profile from MangaBaka API (/v1/my/profile)
      try {
        final meRes = await http
            .get(
              Uri.parse(_meEndpoint),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'User-Agent': AppConstants.userAgent,
              },
            )
            .timeout(
              const Duration(seconds: AppConstants.networkTimeoutSeconds),
            );

        _logger.fine('Profile fetch (me) status: ${meRes.statusCode}');
        if (meRes.statusCode == 200) {
          final body = jsonDecode(meRes.body) as Map<String, dynamic>;
          meProfile = MbProfile.fromMeResponse(body);
        }
      } catch (e) {
        lastError = e;
        _logger.warning('Failed to fetch from /my/profile: $e');
      }

      if (userInfoProfile != null && meProfile != null) {
        final avatar =
            (meProfile.avatarUrl != null && meProfile.avatarUrl!.isNotEmpty)
            ? meProfile.avatarUrl
            : userInfoProfile.avatarUrl;
        return MbProfile(
          id: meProfile.id.isNotEmpty ? meProfile.id : userInfoProfile.id,
          role: meProfile.role.isNotEmpty && meProfile.role != 'user'
              ? meProfile.role
              : userInfoProfile.role,
          scopes: userInfoProfile.scopes.isNotEmpty
              ? userInfoProfile.scopes
              : meProfile.scopes,
          nickname: meProfile.nickname ?? userInfoProfile.nickname,
          preferredUsername:
              meProfile.preferredUsername ?? userInfoProfile.preferredUsername,
          avatarUrl: avatar,
        );
      }

      if (meProfile != null) {
        return meProfile;
      }

      if (userInfoProfile != null) {
        return userInfoProfile;
      }

      throw AuthException(
        message: 'Failed to fetch profile from API',
        originalError: lastError,
      );
    } on AppException catch (e, st) {
      _logger.severe('Profile fetch failed', e, st);
      rethrow;
    } catch (e, st) {
      _logger.severe('Network error during profile fetch', e, st);
      throw AuthException(
        message: 'Network fetch profile failed',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
