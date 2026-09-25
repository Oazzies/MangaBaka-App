import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:win32_registry/win32_registry.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

class WindowsAuthHandler {
  static final _logger = LoggingService.logger;

  /// The sign-in currently waiting on the browser, if any. The browser is a
  /// separate app: closing its tab tells this one nothing, so the wait needs a
  /// way to be ended from our own UI.
  static Completer<String?>? _pending;
  static Uri? _pendingAuthUri;

  /// Ends a pending sign-in as cancelled. No-op when none is waiting.
  static void cancelPending() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(AuthCancelledException());
    }
  }

  /// Opens the authorization page again, for a user who closed the tab.
  static Future<void> reopenBrowser() async {
    final uri = _pendingAuthUri;
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Registers the custom protocol in the Windows Registry.
  static Future<void> registerProtocol(String scheme) async {
    try {
      final appPath = Platform.resolvedExecutable;
      final protocolRegKey = 'Software\\Classes\\$scheme';

      _logger.info(
        'Registering protocol $scheme in Windows Registry for $appPath',
      );

      final key = CURRENT_USER.create(protocolRegKey);
      key.setValue('URL Protocol', RegistryValue.string(''));

      final commandKey = key.create('shell\\open\\command');
      commandKey.setValue('', RegistryValue.string('"$appPath" "%1"'));

      commandKey.close();
      key.close();

      _logger.info('Protocol registration successful');
    } catch (e) {
      _logger.severe('Failed to register protocol $scheme: $e');
    }
  }

  /// Performs the OAuth2 authorization and code exchange flow on Windows.
  static Future<TokenResponse?> authorizeAndExchangeCode({
    required String clientId,
    required String redirectUri,
    required String authorizationEndpoint,
    required String tokenEndpoint,
    required List<String> scopes,
    VoidCallback? onBrowserOpened,
  }) async {
    // Extract scheme and register it
    final scheme = Uri.parse(redirectUri).scheme;
    if (scheme.isNotEmpty) {
      await registerProtocol(scheme);
    }

    final appLinks = AppLinks();

    // 1. Generate PKCE
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateRandomString(16);

    // 2. Prepare Auth URI
    final authUri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'consent',
      },
    );

    // The URI itself carries the state and PKCE challenge; keep it out of
    // the log.
    _logger.info('Opening browser for Windows OAuth sign-in');

    // 3. Listen for redirect before launching. A sign-in already waiting is
    // abandoned first, so its cleanup cannot clobber this one's state.
    cancelPending();
    final completer = Completer<String?>();
    _pending = completer;
    _pendingAuthUri = authUri;
    StreamSubscription? sub;

    sub = appLinks.uriLinkStream.listen(
      (uri) {
        // The query holds the authorization code; log only where it went.
        _logger.fine(
          'Received App Link: ${uri.scheme}://${uri.host}${uri.path}',
        );
        if (uri.toString().startsWith(redirectUri)) {
          final code = uri.queryParameters['code'];
          final receivedState = uri.queryParameters['state'];

          if (receivedState != state) {
            _logger.warning('State mismatch on OAuth redirect; ignoring it');
            return;
          }

          if (completer.isCompleted) return;
          final error = uri.queryParameters['error'];
          if (error != null) {
            _logger.warning('OAuth redirect returned error: $error');
            completer.completeError(
              error == 'access_denied'
                  ? AuthCancelledException()
                  : AuthException(
                      message: 'Authorization failed: $error',
                      code: error,
                    ),
            );
            return;
          }
          if (code != null) {
            completer.complete(code);
          }
        }
      },
      onError: (err) {
        _logger.severe('AppLinks error: $err');
        if (!completer.isCompleted) completer.completeError(err);
      },
    );

    // 4. Launch browser
    if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
      await sub.cancel();
      _pending = null;
      _pendingAuthUri = null;
      throw Exception('Could not launch $authUri');
    }
    onBrowserOpened?.call();

    try {
      // 5. Wait for code (with timeout)
      final code = await completer.future.timeout(const Duration(minutes: 5));
      await sub.cancel();

      if (code == null) return null;

      _logger.info('OAuth code received, exchanging for tokens...');

      // 6. Exchange code for tokens
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'code': code,
          'code_verifier': codeVerifier,
        },
      ).timeout(_tokenTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Token exchange successful on Windows');

        // Map to TokenResponse for compatibility with ProfileAuthService
        return TokenResponse(
          data['access_token'],
          data['refresh_token'],
          _expiryFrom(data['expires_in']),
          data['id_token'],
          'Bearer',
          scopes, // Correctly passing scopes here
          data, // Passing data as additional parameters
        );
      } else {
        _logger.severe(
          'Token exchange failed: ${response.statusCode} ${_oauthError(response.body)}',
        );
        throw Exception('Token exchange failed: ${response.statusCode}');
      }
    } on TimeoutException {
      await sub.cancel();
      _logger.warning('OAuth login timed out');
      throw Exception('Login timed out');
    } catch (e) {
      await sub.cancel();
      rethrow;
    } finally {
      // A newer sign-in may have replaced this one; leave its state alone.
      if (identical(_pending, completer)) {
        _pending = null;
        _pendingAuthUri = null;
      }
    }
  }

  /// Performs a token refresh on Windows.
  static Future<TokenResponse?> refresh({
    required String clientId,
    required String redirectUri,
    required String tokenEndpoint,
    required String refreshToken,
    required List<String> scopes,
  }) async {
    _logger.info('Refreshing token on Windows...');

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'client_id': clientId,
        'refresh_token': refreshToken,
        'scope': scopes.join(' '),
      },
    ).timeout(_tokenTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _logger.info('Token refresh successful on Windows');

      return TokenResponse(
        data['access_token'],
        data['refresh_token'] ??
            refreshToken, // IdPs might not return a new refresh token
        _expiryFrom(data['expires_in']),
        data['id_token'],
        'Bearer',
        scopes,
        data,
      );
    } else {
      _logger.severe(
        'Token refresh failed: ${response.statusCode} ${_oauthError(response.body)}',
      );
      throw ApiException(
        message: 'Token refresh failed',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  /// Bound on a token-endpoint round trip. Refreshes are single-flight in
  /// ProfileAuthService, so one that never returned would stall every
  /// authenticated request behind it.
  static const _tokenTimeout = Duration(seconds: 30);

  /// `expires_in` is specified as an integer, but some servers send a string
  /// or a double; any of those would otherwise throw a TypeError here.
  static DateTime _expiryFrom(Object? raw) {
    final seconds = switch (raw) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 3600,
      _ => 3600,
    };
    return DateTime.now().add(Duration(seconds: seconds));
  }

  /// The OAuth `error` code from a token-endpoint error body, for the log.
  /// Only the code is logged: the rest of the body is not needed to diagnose
  /// a failure and should not end up in a shared log file.
  static String _oauthError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] is String) return data['error'];
    } catch (_) {
      // Not JSON; fall through.
    }
    return '(no OAuth error code)';
  }

  static String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _generateCodeVerifier() {
    return _generateRandomString(128);
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
