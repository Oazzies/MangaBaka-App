import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_network_client.dart';

class ProfileAuthService extends ChangeNotifier {
  final _logger = LoggingService.logger;
  static const _authorizationEndpoint = '${AppConstants.authBaseUrl}/authorize';
  static const _tokenEndpoint = '${AppConstants.authBaseUrl}/token';
  static const _endSessionEndpoint = '${AppConstants.authBaseUrl}/end-session';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final AuthStorage _storage = AuthStorage();
  final AuthNetworkClient _network = AuthNetworkClient();

  MbProfile? _cachedProfile;
  bool _hasSessionCache = false;

  bool get isLoggedIn => _hasSessionCache;
  MbProfile? get cachedProfile => _cachedProfile;

  String get _clientId => dotenv.env['MANGABAKA_APP_CLIENT_ID'] ?? '';
  String get _redirectUri => dotenv.env['MANGABAKA_APP_REDIRECT_URI'] ?? '';

  AuthorizationServiceConfiguration get _serviceConfig =>
      const AuthorizationServiceConfiguration(
        authorizationEndpoint: _authorizationEndpoint,
        tokenEndpoint: _tokenEndpoint,
        endSessionEndpoint: _endSessionEndpoint,
      );

  Future<void> init() async {
    try {
      _hasSessionCache = await hasSession();
      if (_hasSessionCache) {
        _cachedProfile = await _storage.getCachedProfile();
      }
    } catch (e) {
      _logger.warning('Failed to load cached profile: $e');
    }
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(AuthStorage.kAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> login() async {
    try {
      if (_clientId.isEmpty || _redirectUri.isEmpty) {
        throw AuthException(
          message: 'Missing MANGABAKA_APP_CLIENT_ID or MANGABAKA_APP_REDIRECT_URI in .env',
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
      await fetchProfile(forceRefresh: true);
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
      throw AuthException(message: 'Login failed', originalError: e, stackTrace: st);
    }
  }

  Future<void> _persistTokens(TokenResponse response) async {
    try {
      await _storage.write(AuthStorage.kAccessToken, response.accessToken);
      await _storage.write(AuthStorage.kRefreshToken, response.refreshToken);
      await _storage.write(AuthStorage.kIdToken, response.idToken);
      final exp = response.accessTokenExpirationDateTime?.toUtc().toIso8601String();
      if (exp != null) {
        await _storage.write(AuthStorage.kAccessTokenExp, exp);
      }
    } catch (e, st) {
      _logger.severe('Failed to persist tokens: $e\n$st');
      throw AuthException(message: 'Failed to persist tokens', originalError: e, stackTrace: st);
    }
  }

  Future<void> _refreshIfNeeded() async {
    try {
      final expRaw = await _storage.read(AuthStorage.kAccessTokenExp);
      if (expRaw == null) return;

      final exp = DateTime.tryParse(expRaw);
      if (exp == null) return;

      if (DateTime.now().toUtc().isBefore(exp.subtract(const Duration(minutes: 1)))) {
        return;
      }

      final refreshToken = await _storage.read(AuthStorage.kRefreshToken);
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
      final accessToken = await _storage.read(AuthStorage.kAccessToken);

      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException(message: 'Not logged in', code: 'NOT_LOGGED_IN');
      }

      _cachedProfile = await _network.fetchProfile(accessToken);
      await _storage.cacheProfile(_cachedProfile!);
      return _cachedProfile!;
    } catch (e, st) {
      _logger.severe('Failed to fetch profile: $e\n$st');
      if (e is AppException) rethrow;
      throw AuthException(message: 'Failed to fetch profile', originalError: e, stackTrace: st);
    }
  }

  Future<String> getValidAccessToken() async {
    try {
      await _refreshIfNeeded();
      final token = await _storage.read(AuthStorage.kAccessToken);
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
      await _storage.deleteAll();
      _cachedProfile = null;
      _hasSessionCache = false;

      try {
        await getIt<LibraryService>().clearLibrary();
      } catch (e) {
        _logger.warning('Failed to clear library on logout: $e');
      }

      notifyListeners();
    } catch (e, st) {
      _logger.severe('Failed to logout: $e\n$st');
      throw AuthException(message: 'Failed to logout', originalError: e, stackTrace: st);
    }
  }
}
