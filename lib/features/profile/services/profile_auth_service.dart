import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_storage.dart';
import 'package:mangabaka_app/features/profile/services/auth/auth_network_client.dart';
import 'package:mangabaka_app/features/profile/services/auth/desktop_auth_handler.dart';

part 'profile_auth_session_part.dart';

class ProfileAuthService extends ChangeNotifier {
  final _logger = LoggingService.logger;
  static const _authorizationEndpoint = '${AppConstants.authBaseUrl}/authorize';
  static const _tokenEndpoint = '${AppConstants.authBaseUrl}/token';
  static const _endSessionEndpoint = '${AppConstants.authBaseUrl}/end-session';

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final AuthStorage _storage;
  final AuthNetworkClient _network;

  /// Exchanges a refresh token for new tokens. Injected by tests; defaults to
  /// the platform flow ([DesktopAuthHandler] on Windows/Linux, AppAuth elsewhere).
  final Future<TokenResponse?> Function(String refreshToken)? _refresher;

  ProfileAuthService({
    AuthStorage? storage,
    AuthNetworkClient? network,
    @visibleForTesting
    Future<TokenResponse?> Function(String refreshToken)? refresher,
  }) : _storage = storage ?? AuthStorage(),
       _network = network ?? AuthNetworkClient(),
       _refresher = refresher;

  MbProfile? _cachedProfile;
  bool _hasSessionCache = false;

  /// Scopes the stored session was granted, or null for a session from
  /// before they were recorded (which never asked for Stacks).
  List<String>? _grantedScopes;

  /// True while a desktop sign-in is waiting on the user in their browser.
  ///
  /// Drives the "check your browser" prompt. Only desktop flows can be
  /// stranded this way; on mobile the system's auth sheet reports its own
  /// dismissal.
  final ValueNotifier<bool> awaitingBrowser = ValueNotifier(false);

  void cancelLogin() => DesktopAuthHandler.cancelPending();

  Future<void> reopenBrowser() => DesktopAuthHandler.reopenBrowser();

  bool get isLoggedIn => _hasSessionCache;
  MbProfile? get cachedProfile => _cachedProfile;

  /// Whether the session may read and write Stacks. A session signed in
  /// before Stacks existed lacks the scopes; the user has to sign in again.
  bool get hasStackScopes {
    if (!_hasSessionCache) return false;
    bool covers(List<String>? scopes) =>
        scopes != null && AppConstants.stackOauthScopes.every(scopes.contains);
    return covers(_grantedScopes) || covers(_cachedProfile?.scopes);
  }

  /// What a refresh asks for. Asking for more than the original grant is an
  /// `invalid_scope` error, which would end the session, so a session from
  /// before Stacks keeps refreshing with the scopes it was granted.
  List<String> get _refreshScopes =>
      _grantedScopes ?? AppConstants.baseOauthScopes;

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
        _grantedScopes = _parseScopes(
          await _storage.read(AuthStorage.kGrantedScopes),
        );
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
    } catch (e, st) {
      // Startup must not fail on a damaged cache: the user just signs in.
      _logger.warning('Failed to load cached profile during init', e, st);
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

      if (Platform.isWindows || Platform.isLinux) {
        response = await DesktopAuthHandler.authorizeAndExchangeCode(
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
      await _persistGrantedScopes(response);
      _hasSessionCache = true;
      try {
        // Not fetchProfile(): its notification would open the library (and
        // start a sync) before a previous account's entries are cleared.
        await _loadProfile();
        await _reconcileLibraryOwner();
      } finally {
        // The tokens are persisted, so the session exists whether or not the
        // profile could be read; listeners must hear about it either way.
        notifyListeners();
      }
      _logger.info(
        'Login complete for: ${_cachedProfile?.preferredUsername ?? _cachedProfile?.id}',
      );
    } on AuthCancelledException {
      _logger.info('Login cancelled by user');
      rethrow;
    } catch (e, st) {
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

  /// Pref key remembering whose entries the local library database holds.
  static const _libraryOwnerKey =
      '${AppConstants.prefixStorageKey}library_owner_id';

  /// Clears the local library when a *different* account signs in.
  ///
  /// An expired session deliberately leaves the library in place (the same
  /// user usually signs straight back in). But the sync watermark outlives it:
  /// a second account would only receive an incremental catch-up, and its
  /// library would be shown merged with the first account's entries.
  Future<void> _reconcileLibraryOwner() async {
    final id = _cachedProfile?.id ?? '';
    if (id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getString(_libraryOwnerKey);
      if (previous != null && previous != id) {
        _logger.info('Different account signed in; clearing local library');
        await getIt<LibraryService>().clearLibrary();
      }
      await prefs.setString(_libraryOwnerKey, id);
    } catch (e) {
      _logger.warning('Could not reconcile library owner: $e');
    }
  }

  static List<String>? _parseScopes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.split(' ').where((s) => s.isNotEmpty).toList();
  }

  Future<void> _persistGrantedScopes(TokenResponse response) =>
      _persistGrantedScopesImpl(this, response);

  Future<void> _persistTokens(TokenResponse response) =>
      _persistTokensImpl(this, response);

  /// Guards against concurrent refreshes. With rotating refresh tokens, two
  /// parallel refreshes would race: the first invalidates the token the second
  /// is still using, permanently breaking the session. Callers share one
  /// in-flight refresh instead.
  Future<void>? _refreshInFlight;

  Future<void> _refreshIfNeeded({bool force = false}) {
    return _refreshInFlight ??= _runRefresh(
      force: force,
    ).whenComplete(() => _refreshInFlight = null);
  }

  void _notifyStateChanged() => notifyListeners();

  Future<void> _runRefresh({bool force = false}) =>
      _runRefreshImpl(this, force: force);

  Future<TokenResponse?> _platformRefresh(String refreshToken) =>
      _platformRefreshImpl(this, refreshToken);

  /// Sends a request that needs the user's bearer token, recovering once
  /// from an HTTP 401.
  ///
  /// Never returns a 401; clears the session and throws
  /// [SessionExpiredException] if recovery fails.
  Future<http.Response> sendAuthorized(
    Future<http.Response> Function(String token) send,
  ) => _sendAuthorizedImpl(this, send);

  Future<void> _clearSession() => _clearSessionImpl(this);

  Future<MbProfile> fetchProfile({bool forceRefresh = false}) =>
      _fetchProfileImpl(this, forceRefresh: forceRefresh);

  /// Fetches and caches the profile without notifying listeners.
  Future<MbProfile> _loadProfile() => _loadProfileImpl(this);

  Future<String> getValidAccessToken() => _getValidAccessTokenImpl(this);

  Future<void> logout() => _logoutImpl(this);
}
