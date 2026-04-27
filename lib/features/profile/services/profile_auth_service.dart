import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/features/profile/models/mb_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProfileAuthService extends ChangeNotifier {
  final _logger = LoggingService.logger;
  static const _authorizationEndpoint =
      '${AppConstants.authBaseUrl}/authorize';
  static const _tokenEndpoint = '${AppConstants.authBaseUrl}/token';
  static const _endSessionEndpoint =
      '${AppConstants.authBaseUrl}/end-session';
  static const _meEndpoint = '${AppConstants.baseApiUrl}/me';
  static const _userInfoEndpoint = '${AppConstants.authBaseUrl}/userinfo';

  static const _kAccessToken = 'mb_access_token';
  static const _kRefreshToken = 'mb_refresh_token';
  static const _kIdToken = 'mb_id_token';
  static const _kAccessTokenExp = 'mb_access_token_exp';
  static const _kProfileCache = 'mb_profile_cache';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      sharedPreferencesName: 'bakahyou_secure_storage_v2',
    ),
  );

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
    } on PlatformException catch (e) {
      _logger.severe('Secure storage error (likely decryption failure): $e');
      // If we can't read the storage due to key issues, clear everything
      // so the app can function again (user will need to log in).
      await _storage.deleteAll();
      return false;
    } catch (e) {
      _logger.severe('Failed to check session status: $e');
      return false;
    }
  }

  Future<void> login() async {
    try {
      if (_clientId.isEmpty || _redirectUri.isEmpty) {
        throw AuthException(
          message: 'Missing BAKAHYOU_CLIENT_ID or BAKAHYOU_REDIRECT_URI in .env',
          code: 'MISSING_CONFIG',
        );
      }

      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: AppConstants.oauthScopes,
          promptValues: const ['consent'],
        ),
      );

      await _persistTokens(response);
      _hasSessionCache = true;
      notifyListeners();
    } catch (e, st) {
      if (e is PlatformException &&
          (e.code == 'authorize_and_exchange_code_failed' ||
              e.code == 'user_cancelled')) {
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('cancelled') || msg.contains('canceled') || msg.contains('user')) {
          _logger.info('Login cancelled by user');
          throw AuthCancelledException();
        }
      }

      _logger.severe('Login failed: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(
          message: 'Login failed', originalError: e, stackTrace: st);
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
    } catch (e, st) {
      _logger.severe('Failed to persist tokens: $e\n$st');
      throw AuthException(message: 'Failed to persist tokens', originalError: e, stackTrace: st);
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
          scopes: AppConstants.oauthScopes,
        ),
      );

      await _persistTokens(response);
    } catch (e, st) {
      _logger.severe('Failed to refresh tokens: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Failed to refresh tokens', originalError: e, stackTrace: st);
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
        throw AuthException(message: 'Not logged in', code: 'NOT_LOGGED_IN');
      }

      // Try /v1/me first
      final res = await http.get(
        Uri.parse(_meEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': AppConstants.userAgent,
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
            'User-Agent': AppConstants.userAgent,
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
          throw AuthException(message: 'Failed to fetch profile from userinfo endpoint', code: '${userinfoRes.statusCode}');
        }
      } else {
        _logger.severe(
          'Failed to fetch profile from me endpoint: ${res.statusCode} ${res.body}',
        );
        throw AuthException(message: 'Failed to fetch profile from me endpoint', code: '${res.statusCode}');
      }
    } catch (e, st) {
      _logger.severe('Failed to fetch profile: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Failed to fetch profile', originalError: e, stackTrace: st);
    }
  }

  Future<String> getValidAccessToken() async {
    try {
      await _refreshIfNeeded();

      final token = await _storage.read(key: _kAccessToken);
      if (token == null || token.isEmpty) {
        throw AuthException(message: 'Not logged in', code: 'NOT_LOGGED_IN');
      }

      return token;
    } catch (e, st) {
      _logger.severe('Failed to get valid access token: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Failed to get valid access token', originalError: e, stackTrace: st);
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
      notifyListeners();
    } catch (e, st) {
      _logger.severe('Failed to logout: $e\n$st');
      throw AuthException(message: 'Failed to logout', originalError: e, stackTrace: st);
    }
  }
}
