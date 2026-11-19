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

  /// Null for a session from before scopes were recorded, which never asked for Stacks.
  List<String>? _grantedScopes;

  /// Only desktop sign-in can strand the user in a browser; mobile's auth sheet reports dismissal.
  final ValueNotifier<bool> awaitingBrowser = ValueNotifier(false);

  void cancelLogin() => DesktopAuthHandler.cancelPending();

  Future<void> reopenBrowser() => DesktopAuthHandler.reopenBrowser();

  bool get isLoggedIn => _hasSessionCache;
  MbProfile? get cachedProfile => _cachedProfile;

  bool get hasStackScopes {
    if (!_hasSessionCache) return false;
    bool covers(List<String>? scopes) =>
        scopes != null && AppConstants.stackOauthScopes.every(scopes.contains);
    return covers(_grantedScopes) || covers(_cachedProfile?.scopes);
  }

  /// Never asks a refresh for more than the grant: `invalid_scope` would end the session.
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
        // Not fetchProfile(): it notifies, starting a sync before the old account's entries clear.
        await _loadProfile();
        await _reconcileLibraryOwner();
      } finally {
        // The tokens are persisted, so listeners hear of the session even if the profile failed.
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

  static const _libraryOwnerKey =
      '${AppConstants.prefixStorageKey}library_owner_id';

  /// An expired session keeps the library, but the sync watermark outlives it: a different account
  /// would get only an incremental catch-up, merged with the previous account's entries.
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

  /// Rotating refresh tokens: a parallel refresh would reuse a revoked token and kill the session.
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

  /// Recovers once from a 401; never returns one, throwing [SessionExpiredException] instead.
  Future<http.Response> sendAuthorized(
    Future<http.Response> Function(String token) send,
  ) => _sendAuthorizedImpl(this, send);

  Future<void> _clearSession() => _clearSessionImpl(this);

  Future<MbProfile> fetchProfile({bool forceRefresh = false}) =>
      _fetchProfileImpl(this, forceRefresh: forceRefresh);

  /// Unlike [fetchProfile], does not notify listeners.
  Future<MbProfile> _loadProfile() => _loadProfileImpl(this);

  Future<String> getValidAccessToken() => _getValidAccessTokenImpl(this);

  Future<void> logout() => _logoutImpl(this);
}
