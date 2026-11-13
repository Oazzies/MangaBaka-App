import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';

class DesktopAuthTokens {
  static final _logger = LoggingService.logger;
  static const tokenTimeout = Duration(seconds: 30);

  static Future<TokenResponse?> refresh({
    required String clientId,
    required String redirectUri,
    required String tokenEndpoint,
    required String refreshToken,
    required List<String> scopes,
  }) async {
    _logger.info('Refreshing token on desktop...');

    final response = await http
        .post(
          Uri.parse(tokenEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'refresh_token',
            'client_id': clientId,
            'refresh_token': refreshToken,
            'scope': scopes.join(' '),
          },
        )
        .timeout(tokenTimeout);

    if (response.statusCode == 200) {
      final data = tokenBody(response.body);
      _logger.info('Token refresh successful on desktop');

      return TokenResponse(
        data['access_token'] as String,
        (data['refresh_token'] as String?) ?? refreshToken,
        expiryFrom(data['expires_in']),
        data['id_token'] as String?,
        'Bearer',
        scopes,
        data,
      );
    }
    _logger.severe(
      'Token refresh failed: ${response.statusCode} ${oauthError(response.body)}',
    );
    throw ApiException(
      message: 'Token refresh failed',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  static Map<String, dynamic> tokenBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('token response is not a JSON object');
    }
    final access = decoded['access_token'];
    if (access is! String || access.isEmpty) {
      throw const FormatException('token response has no access_token');
    }
    for (final key in const ['refresh_token', 'id_token']) {
      if (decoded[key] != null && decoded[key] is! String) {
        throw FormatException('token response has a non-string $key');
      }
    }
    return decoded;
  }

  static DateTime expiryFrom(Object? raw) {
    final seconds = switch (raw) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 3600,
      _ => 3600,
    };
    return DateTime.now().add(Duration(seconds: seconds));
  }

  static String oauthError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] is String) return data['error'];
    } on FormatException {
      // Not JSON; fall through.
    }
    return '(no OAuth error code)';
  }

  static String generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String generateCodeVerifier() => generateRandomString(128);

  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
