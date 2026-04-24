import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/utils/services/logging_service.dart';

import 'package:bakahyou/features/profile/models/mb_profile.dart';

class ProfileAuthService {
  final _logger = LoggingService.logger;
  static const _authorizationEndpoint =
      'https://mangabaka.org/auth/oauth2/authorize';
  static const _tokenEndpoint = 'https://mangabaka.org/auth/oauth2/token';
  static const _endSessionEndpoint =
      'https://mangabaka.org/auth/oauth2/end-session';
  static const _meEndpoint = 'https://api.mangabaka.dev/v1/me';
  static const _userInfoEndpoint = 'https://mangabaka.org/auth/oauth2/userinfo';

  static const _kAccessToken = 'mb_access_token';
  static const _kRefreshToken = 'mb_refresh_token';
  static const _kIdToken = 'mb_id_token';
  static const _kAccessTokenExp = 'mb_access_token_exp';
  static const _kProfileCache = 'mb_profile_cache';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  MbProfile? _cachedProfile;
  bool _hasSessionCache = false;

  bool get isLoggedIn => _hasSessionCache;
  MbProfile? get cachedProfile => _cachedProfile;

  String get _clientId => dotenv.env['BAKAHYOU_CLIENT_ID'] ?? '';
  String get _redirectUri => dotenv.env['BAKAHYOU_REDIRECT_URI'] ?? '';

  AuthorizationServiceConfiguration get _serviceConfig =>
      const AuthorizationServiceConfiguration(
        authorizationEndpoint: _authorizationEndpoint,
        tokenEndpoint: _tokenEndpoint,
        endSessionEndpoint: _endSessionEndpoint,
      );

  Future<void> init() async {
    _hasSessionCache = await hasSession();
    if (_hasSessionCache) {
      try {
        final cachedString = await _storage.read(key: _kProfileCache);
        if (cachedString != null) {
          _cachedProfile = MbProfile.fromJson(jsonDecode(cachedString));
        }
      } catch (e) {
        _logger.warning('Failed to load cached profile: $e');
      }
    }
  }

  Future<bool> hasSession() async {
    try {
      final token = await _storage.read(key: _kAccessToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      _logger.severe('Failed to check session status: $e');
      return false;
    }
  }

  Future<void> login() async {
    try {
      if (_clientId.isEmpty || _redirectUri.isEmpty) {
        throw Exception(
          'Missing BAKAHYOU_CLIENT_ID or BAKAHYOU_REDIRECT_URI in .env',
        );
      }

      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: const [
            'openid',
            'profile',
            'library.read',
            'library.write',
            'offline_access',
          ],
          promptValues: const ['consent'],
        ),
      );

      await _persistTokens(response);
      _hasSessionCache = true;
    } catch (e) {
      _logger.severe('Login failed: $e');
      throw Exception('Login failed.');
    }
  }

  Future<void> _persistTokens(TokenResponse response) async {
    try {
      await _storage.write(key: _kAccessToken, value: response.accessToken);
      await _storage.write(key: _kRefreshToken, value: response.refreshToken);
      await _storage.write(key: _kIdToken, value: response.idToken);
      final exp = response.accessTokenExpirationDateTime
          ?.toUtc()
          .toIso8601String();
      if (exp != null) {
        await _storage.write(key: _kAccessTokenExp, value: exp);
      }
    } catch (e) {
      _logger.severe('Failed to persist tokens: $e');
      throw Exception('Failed to persist tokens.');
    }
  }

  Future<void> _refreshIfNeeded() async {
    try {
      final expRaw = await _storage.read(key: _kAccessTokenExp);
      if (expRaw == null) return;

      final exp = DateTime.tryParse(expRaw);
      if (exp == null) return;

      if (DateTime.now().toUtc().isBefore(
        exp.subtract(const Duration(minutes: 1)),
      )) {
        return;
      }

      final refreshToken = await _storage.read(key: _kRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return;

      final response = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfig,
          refreshToken: refreshToken,
          scopes: const [
            'openid',
            'profile',
            'library.read',
            'library.write',
            'offline_access',
          ],
        ),
      );

      await _persistTokens(response);
    } catch (e) {
      _logger.severe('Failed to refresh tokens: $e');
      throw Exception('Failed to refresh tokens.');
    }
  }

  Future<MbProfile> fetchProfile({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedProfile != null) {
        return _cachedProfile!;
      }

      await _refreshIfNeeded();
      final accessToken = await _storage.read(key: _kAccessToken);

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Not logged in');
      }

      // Try /v1/me first
      final res = await http.get(
        Uri.parse(_meEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _cachedProfile = MbProfile.fromMeResponse(body);
        await _storage.write(key: _kProfileCache, value: jsonEncode(_cachedProfile!.toJson()));
        return _cachedProfile!;
      } else if (res.statusCode == 404) {
        // Fallback to OIDC userinfo endpoint
        final userinfoRes = await http.get(
          Uri.parse(_userInfoEndpoint),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': 'BakaHyou/0.0 (oazziesmail@gmail.com)',
          },
        );
        if (userinfoRes.statusCode == 200) {
          final body = jsonDecode(userinfoRes.body) as Map<String, dynamic>;
          _cachedProfile = MbProfile.fromUserInfo(body);
          await _storage.write(key: _kProfileCache, value: jsonEncode(_cachedProfile!.toJson()));
          return _cachedProfile!;
        } else {
          _logger.severe(
            'Failed to fetch profile from userinfo endpoint: ${userinfoRes.statusCode} ${userinfoRes.body}',
          );
          throw Exception('Failed to fetch profile: ${userinfoRes.statusCode}');
        }
      } else {
        _logger.severe(
          'Failed to fetch profile from me endpoint: ${res.statusCode} ${res.body}',
        );
        throw Exception('Failed to fetch profile: ${res.statusCode}');
      }
    } catch (e) {
      _logger.severe('Failed to fetch profile: $e');
      throw Exception('Failed to fetch profile.');
    }
  }

  Future<String> getValidAccessToken() async {
    try {
      await _refreshIfNeeded();

      final token = await _storage.read(key: _kAccessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Not logged in');
      }

      return token;
    } catch (e) {
      _logger.severe('Failed to get valid access token: $e');
      throw Exception('Failed to get valid access token.');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: _kAccessToken);
      await _storage.delete(key: _kRefreshToken);
      await _storage.delete(key: _kIdToken);
      await _storage.delete(key: _kAccessTokenExp);
      await _storage.delete(key: _kProfileCache);
      _cachedProfile = null;
      _hasSessionCache = false;
    } catch (e) {
      _logger.severe('Failed to logout: $e');
      throw Exception('Failed to logout.');
    }
  }
}
