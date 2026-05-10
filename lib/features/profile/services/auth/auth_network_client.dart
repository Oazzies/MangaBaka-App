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
    try {
      final res = await http.get(
        Uri.parse(_meEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': AppConstants.userAgent,
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return MbProfile.fromMeResponse(body);
      } else if (res.statusCode == 404) {
        final userinfoRes = await http.get(
          Uri.parse(_userInfoEndpoint),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': AppConstants.userAgent,
          },
        );
        if (userinfoRes.statusCode == 200) {
          final body = jsonDecode(userinfoRes.body) as Map<String, dynamic>;
          return MbProfile.fromUserInfo(body);
        } else {
          throw AuthException(message: 'Failed to fetch profile from userinfo', code: '${userinfoRes.statusCode}');
        }
      } else {
        throw AuthException(message: 'Failed to fetch profile from me', code: '${res.statusCode}');
      }
    } catch (e, st) {
      _logger.severe('Network fetch profile error: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Network fetch profile failed', originalError: e, stackTrace: st);
    }
  }
}
