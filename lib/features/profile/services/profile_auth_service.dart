import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_network_client.dart';
import 'package:mangabaka_app/features/profile/services/auth/windows_auth_handler.dart';

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

  /// True while a desktop sign-in is waiting on the user in their browser.
  ///
  /// Drives the "check your browser" prompt. Only the Windows flow can be
  /// stranded this way; on mobile the system's auth sheet reports its own
  /// dismissal.
  final ValueNotifier<bool> awaitingBrowser = ValueNotifier(false);

  void cancelLogin() => WindowsAuthHandler.cancelPending();

  Future<void> reopenBrowser() => WindowsAuthHandler.reopenBrowser();

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
    _logger.info('Initializing ProfileAuthService...');
    try {
      _hasSessionCache = await hasSession();
      if (_hasSessionCache) {
        _logger.info('Found active session in storage');
        _cachedProfile = await _storage.getCachedProfile();
        if (_cachedProfile != null) {
          _logger.fine(
            'Loaded cached profile for: ${_cachedProfile!.preferredUsername ?? _cachedProfile!.id}',
          );
        }
        // Background refresh profile so avatar and details are up-to-date
        fetchProfile(forceRefresh: true).then(
          (_) {},
          onError: (e) {
            _logger.fine('Background profile refresh on init failed: $e');
          },
        );
      } else {
        _logger.fine('No active session found');
      }
    } catch (e) {
      _logger.warning('Failed to load cached profile during init: $e');
    }
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(AuthStorage.kAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> login() async {
    _logger.info('Starting OAuth2 login flow...');
    try {
      if (_clientId.isEmpty || _redirectUri.isEmpty) {
        _logger.severe('OAuth configuration missing from .env');
        throw AuthException(
          message:
              'Missing MANGABAKA_APP_CLIENT_ID or MANGABAKA_APP_REDIRECT_URI in .env',
          code: 'MISSING_CONFIG',
        );
      }

      TokenResponse? response;

      if (Platform.isWindows) {
        response = await WindowsAuthHandler.authorizeAndExchangeCode(
          clientId: _clientId,
          redirectUri: _redirectUri,
          authorizationEndpoint: _authorizationEndpoint,
          tokenEndpoint: _tokenEndpoint,
          scopes: AppConstants.oauthScopes,
          onBrowserOpened: () => awaitingBrowser.value = true,
        );
      } else {
        response = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            _clientId,
            _redirectUri,
            serviceConfiguration: _serviceConfig,
            scopes: AppConstants.oauthScopes,
            promptValues: const ['consent'],
          ),
        );
      }

      if (response == null) {
        throw AuthException(
          message: 'Login failed: No response from auth server',
        );
      }

      _logger.info('OAuth2 authorization successful. Persisting tokens...');
      await _persistTokens(response);
      _hasSessionCache = true;
      await fetchProfile(forceRefresh: true);
      _logger.info(
        'Login complete for: ${_cachedProfile?.preferredUsername ?? _cachedProfile?.id}',
      );
      notifyListeners();
    } catch (e, st) {
      if (e is AuthCancelledException) {
        _logger.info('Login cancelled by user');
        rethrow;
      }
      if (e is PlatformException &&
          (e.code == 'authorize_and_exchange_code_failed' ||
              e.code == 'user_cancelled')) {
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('cancelled') ||
            msg.contains('canceled') ||
            msg.contains('user')) {
          _logger.info('Login cancelled by user');
          throw AuthCancelledException();
        }
      }
      _logger.severe('Login flow failed', e, st);
      if (e is AppException) rethrow;
      throw AuthException(
        message: 'Login failed',
        originalError: e,
        stackTrace: st,
      );
    } finally {
      awaitingBrowser.value = false;
    }
  }

  Future<void> _persistTokens(TokenResponse response) async {
    try {
      await _storage.write(AuthStorage.kAccessToken, response.accessToken);
      // A refresh response may omit the refresh/id token when the provider
      // does not rotate them. Writing null would delete the stored one and
      // break the next refresh, so only overwrite with a real value.
      if (response.refreshToken?.isNotEmpty ?? false) {
        await _storage.write(AuthStorage.kRefreshToken, response.refreshToken);
      }
      if (response.idToken?.isNotEmpty ?? false) {
        await _storage.write(AuthStorage.kIdToken, response.idToken);
      }
      final exp = response.accessTokenExpirationDateTime
          ?.toUtc()
          .toIso8601String();
      if (exp != null) {
        _logger.fine('Token expiration set to: $exp');
        await _storage.write(AuthStorage.kAccessTokenExp, exp);
      } else {
        // An expiry left over from the previous token would be wrong for
        // this one; without one, refresh is attempted only on demand.
        await _storage.delete(AuthStorage.kAccessTokenExp);
      }
    } catch (e, st) {
      _logger.severe('Failed to persist tokens', e, st);
      throw AuthException(
        message: 'Failed to persist tokens',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Guards against concurrent refreshes. With rotating refresh tokens, two
  /// parallel refreshes would race: the first invalidates the token the second
  /// is still using, permanently breaking the session. Callers share one
  /// in-flight refresh instead.
  Future<void>? _refreshInFlight;

  Future<void> _refreshIfNeeded() {
    return _refreshInFlight ??= _runRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<void> _runRefresh() async {
    final expRaw = await _storage.read(AuthStorage.kAccessTokenExp);
    if (expRaw == null) {
      _logger.fine('No token expiration found, assuming refresh not needed');
      return;
    }

    final exp = DateTime.tryParse(expRaw);
    if (exp == null) return;

    final now = DateTime.now().toUtc();
    final threshold = exp.subtract(const Duration(minutes: 5));

    if (now.isBefore(threshold)) {
      _logger.fine('Access token still valid. Expires at: $exp');
      return;
    }

    _logger.info(
      'Access token expiring soon or already expired. Attempting refresh...',
    );
    final refreshToken = await _storage.read(AuthStorage.kRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      _logger.warning('No refresh token available to perform refresh');
      await _clearSession();
      throw SessionExpiredException();
    }

    TokenResponse? response;
    try {
      if (Platform.isWindows) {
        response = await WindowsAuthHandler.refresh(
          clientId: _clientId,
          redirectUri: _redirectUri,
          tokenEndpoint: _tokenEndpoint,
          refreshToken: refreshToken,
          scopes: AppConstants.oauthScopes,
        );
      } else {
        response = await _appAuth.token(
          TokenRequest(
            _clientId,
            _redirectUri,
            serviceConfiguration: _serviceConfig,
            refreshToken: refreshToken,
            scopes: AppConstants.oauthScopes,
          ),
        );
      }
    } catch (e, st) {
      _logger.severe('Token refresh failed', e, st);
      // An invalid_grant (HTTP 400/401) means the refresh token is dead and no
      // amount of retrying will help — clear the session and force re-login.
      // Anything else (network, 5xx) stays retryable.
      if (_isInvalidGrant(e)) {
        await _clearSession();
        throw SessionExpiredException(originalError: e, stackTrace: st);
      }
      throw AuthException(
        message: 'Failed to refresh tokens',
        originalError: e,
        stackTrace: st,
      );
    }

    if (response == null) {
      throw AuthException(
        message: 'Token refresh failed: No response from auth server',
      );
    }

    _logger.info('Token refresh successful');
    await _persistTokens(response);
  }

  /// Detects an unrecoverable `invalid_grant` from either the Windows handler
  /// (typed [ApiException]) or flutter_appauth (a [PlatformException] whose
  /// payload carries the OAuth error).
  bool _isInvalidGrant(Object e) {
    if (e is ApiException) {
      return e.statusCode == 400 || e.statusCode == 401;
    }
    if (e is PlatformException) {
      final blob = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'
          .toLowerCase();
      return blob.contains('invalid_grant') ||
          blob.contains('invalid_token') ||
          blob.contains(' 400') ||
          blob.contains(' 401');
    }
    return false;
  }

  /// Drops the local credentials and flips state to logged-out so the UI can
  /// route the user back to login. Library data is left intact (it is
  /// server-backed and re-syncs on the next login); explicit [logout] is the
  /// path that also clears the library.
  Future<void> _clearSession() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      _logger.warning('Failed to clear storage during session expiry: $e');
    }
    _cachedProfile = null;
    _hasSessionCache = false;
    notifyListeners();
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
      notifyListeners();
      return _cachedProfile!;
    } catch (e, st) {
      _logger.severe('Failed to fetch profile', e, st);
      if (e is AppException) rethrow;
      throw AuthException(
        message: 'Failed to fetch profile',
        originalError: e,
        stackTrace: st,
      );
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
      _logger.severe('Failed to get valid access token', e, st);
      if (e is AppException) rethrow;
      throw AuthException(
        message: 'Failed to get valid access token',
        originalError: e,
        stackTrace: st,
      );
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
      _logger.severe('Failed to logout', e, st);
      throw AuthException(
        message: 'Failed to logout',
        originalError: e,
        stackTrace: st,
      );
    }
  }
}
