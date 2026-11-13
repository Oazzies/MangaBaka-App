import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/profile/services/auth/desktop_auth_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32_registry/win32_registry.dart';

class DesktopAuthHandler {
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

  /// Registers the custom protocol on desktop platforms (Windows registry or Linux desktop entry).
  static Future<void> registerProtocol(String scheme) async {
    if (Platform.isWindows) {
      await _registerWindowsProtocol(scheme);
    } else if (Platform.isLinux) {
      await _registerLinuxProtocol(scheme);
    }
  }

  /// Registers the custom protocol in the Windows Registry.
  static Future<void> _registerWindowsProtocol(String scheme) async {
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

      _logger.info('Protocol registration successful on Windows');
    } on Exception catch (e, st) {
      // Registry writes (WindowsException) only; sign-in then falls back to
      // whatever handler is registered already.
      _logger.severe('Failed to register protocol $scheme on Windows', e, st);
    }
  }

  /// Registers the custom protocol on Linux via a .desktop file in
  /// ~/.local/share/applications and xdg-mime.
  static Future<void> _registerLinuxProtocol(String scheme) async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return;

      final appDir = Directory('$homeDir/.local/share/applications');
      if (!appDir.existsSync()) appDir.createSync(recursive: true);

      final desktopFile = File('${appDir.path}/mangabaka.desktop');
      final execPath = Platform.resolvedExecutable;

      final schemes = {'mangabaka', 'dev.oazzies.mangabaka', scheme};
      final mimeTypes = schemes.map((s) => 'x-scheme-handler/$s;').join();

      final contents = '''
[Desktop Entry]
Type=Application
Name=MangaBaka
Exec="$execPath" %u
Icon=mangabaka
Terminal=false
Categories=Utility;
MimeType=$mimeTypes
StartupWMClass=dev.oazzies.mangabaka_app
''';

      if (!desktopFile.existsSync() ||
          desktopFile.readAsStringSync() != contents) {
        desktopFile.writeAsStringSync(contents);
      }

      await Process.run('xdg-mime', [
        'default',
        'mangabaka.desktop',
        'x-scheme-handler/$scheme',
      ]);
      await Process.run('update-desktop-database', [appDir.path]);

      _logger.info('Protocol registration for $scheme successful on Linux');
    } catch (e, st) {
      _logger.warning('Failed to register protocol $scheme on Linux', e, st);
    }
  }

  /// Performs the OAuth2 authorization and code exchange flow on desktop.
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
    final codeVerifier = DesktopAuthTokens.generateCodeVerifier();
    final codeChallenge = DesktopAuthTokens.generateCodeChallenge(codeVerifier);
    final state = DesktopAuthTokens.generateRandomString(16);

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

    _logger.info('Opening browser for desktop OAuth sign-in');

    // 3. Listen for redirect before launching. A sign-in already waiting is
    // abandoned first, so its cleanup cannot clobber this one's state.
    cancelPending();
    final completer = Completer<String?>();
    _pending = completer;
    _pendingAuthUri = authUri;
    StreamSubscription? sub;

    sub = appLinks.uriLinkStream.listen(
      (uri) {
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

    try {
      // 4. Launch browser. Inside the try so a launcher that throws (rather
      // than returning false) still cancels the subscription and clears the
      // pending state.
      if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
        throw AuthException(
          message: 'Could not launch the browser for sign-in',
          code: 'BROWSER_LAUNCH_FAILED',
        );
      }
      onBrowserOpened?.call();

      // 5. Wait for code (with timeout)
      final code = await completer.future.timeout(const Duration(minutes: 5));
      await sub.cancel();

      if (code == null) return null;

      _logger.info('OAuth code received, exchanging for tokens...');

      // 6. Exchange code for tokens
      final response = await http
          .post(
            Uri.parse(tokenEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'authorization_code',
              'client_id': clientId,
              'redirect_uri': redirectUri,
              'code': code,
              'code_verifier': codeVerifier,
            },
          )
          .timeout(_tokenTimeout);

      if (response.statusCode == 200) {
        final data = DesktopAuthTokens.tokenBody(response.body);
        _logger.info('Token exchange successful on desktop');

        // Map to TokenResponse for compatibility with ProfileAuthService
        return TokenResponse(
          data['access_token'] as String,
          data['refresh_token'] as String?,
          DesktopAuthTokens.expiryFrom(data['expires_in']),
          data['id_token'] as String?,
          'Bearer',
          scopes,
          data,
        );
      } else {
        _logger.severe(
          'Token exchange failed: ${response.statusCode} ${DesktopAuthTokens.oauthError(response.body)}',
        );
        throw ApiException(
          message: 'Token exchange failed',
          statusCode: response.statusCode,
          code: 'TOKEN_EXCHANGE_FAILED',
        );
      }
    } on TimeoutException {
      await sub.cancel();
      _logger.warning('OAuth login timed out');
      throw AuthException(message: 'Login timed out', code: 'LOGIN_TIMEOUT');
    } catch (e, st) {
      _logger.warning('OAuth login flow interrupted', e, st);
      await sub.cancel();
      rethrow;
    } finally {
      if (identical(_pending, completer)) {
        _pending = null;
        _pendingAuthUri = null;
      }
    }
  }

  /// Performs a token refresh on desktop.
  static Future<TokenResponse?> refresh({
    required String clientId,
    required String redirectUri,
    required String tokenEndpoint,
    required String refreshToken,
    required List<String> scopes,
  }) => DesktopAuthTokens.refresh(
    clientId: clientId,
    redirectUri: redirectUri,
    tokenEndpoint: tokenEndpoint,
    refreshToken: refreshToken,
    scopes: scopes,
  );

  static const _tokenTimeout = DesktopAuthTokens.tokenTimeout;
}
