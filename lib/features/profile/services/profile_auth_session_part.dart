part of 'profile_auth_service.dart';

Future<void> _runRefreshImpl(
  ProfileAuthService self, {
  bool force = false,
}) async {
  if (!force) {
    final expRaw = await self._storage.read(AuthStorage.kAccessTokenExp);
    if (expRaw == null) {
      self._logger.fine(
        'No token expiration found, assuming refresh not needed',
      );
      return;
    }

    final exp = DateTime.tryParse(expRaw);
    if (exp == null) return;

    final now = DateTime.now().toUtc();
    final threshold = exp.subtract(const Duration(minutes: 5));

    if (now.isBefore(threshold)) {
      self._logger.fine('Access token still valid. Expires at: $exp');
      return;
    }
  }

  self._logger.info(
    force
        ? 'Access token rejected by the server. Attempting refresh...'
        : 'Access token expiring soon or already expired. Attempting refresh...',
  );
  final refreshToken = await self._storage.read(AuthStorage.kRefreshToken);
  if (refreshToken == null || refreshToken.isEmpty) {
    self._logger.warning('No refresh token available to perform refresh');
    await self._clearSession();
    throw SessionExpiredException();
  }

  TokenResponse? response;
  try {
    response = await (self._refresher ?? self._platformRefresh)(refreshToken);
  } catch (e, st) {
    self._logger.severe('Token refresh failed', e, st);
    // An invalid_grant (HTTP 400/401) means the refresh token is dead and no
    // amount of retrying will help — clear the session and force re-login.
    // Anything else (network, 5xx) stays retryable.
    if (_isInvalidGrantError(e)) {
      await self._clearSession();
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

  self._logger.info('Token refresh successful');
  await self._persistTokens(response);
}

bool _isInvalidGrantError(Object e) {
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

Future<http.Response> _sendAuthorizedImpl(
  ProfileAuthService self,
  Future<http.Response> Function(String token) send,
) async {
  final token = await self.getValidAccessToken();
  final response = await send(token);
  if (response.statusCode != 401) return response;

  self._logger.warning('Request rejected with 401; refreshing the session');
  final fresh = await _recoverFromUnauthorizedImpl(self, token);
  final retried = await send(fresh);
  if (retried.statusCode != 401) return retried;

  self._logger.severe('Request rejected with 401 after a token refresh');
  await self._clearSession();
  throw SessionExpiredException();
}

Future<String> _recoverFromUnauthorizedImpl(
  ProfileAuthService self,
  String rejected,
) async {
  final inFlight = self._refreshInFlight;
  if (inFlight != null) await inFlight;

  var token = await self._storage.read(AuthStorage.kAccessToken);
  if (token == null || token.isEmpty) throw SessionExpiredException();
  if (token != rejected) return token;

  await self._refreshIfNeeded(force: true);
  token = await self._storage.read(AuthStorage.kAccessToken);
  if (token == null || token.isEmpty) throw SessionExpiredException();
  return token;
}

Future<void> _clearSessionImpl(ProfileAuthService self) async {
  try {
    await self._storage.deleteAll();
  } catch (e) {
    self._logger.warning(
      'Failed to clear storage during session expiry: $e',
    );
  }
  self._cachedProfile = null;
  self._grantedScopes = null;
  self._hasSessionCache = false;
  self._notifyStateChanged();
}

Future<MbProfile> _fetchProfileImpl(
  ProfileAuthService self, {
  bool forceRefresh = false,
}) async {
  try {
    if (!forceRefresh && self._cachedProfile != null) {
      return self._cachedProfile!;
    }

    final profile = await self._loadProfile();
    self._notifyStateChanged();
    return profile;
  } on AppException catch (e, st) {
    self._logger.severe('Failed to fetch profile', e, st);
    rethrow;
  } catch (e, st) {
    self._logger.severe('Failed to fetch profile', e, st);
    throw AuthException(
      message: 'Failed to fetch profile',
      originalError: e,
      stackTrace: st,
    );
  }
}

Future<MbProfile> _loadProfileImpl(ProfileAuthService self) async {
  await self._refreshIfNeeded();
  final accessToken = await self._storage.read(AuthStorage.kAccessToken);

  if (accessToken == null || accessToken.isEmpty) {
    throw AuthException(message: 'Not logged in', code: 'NOT_LOGGED_IN');
  }

  final profile = await self._network.fetchProfile(accessToken);
  self._cachedProfile = profile;
  await self._storage.cacheProfile(profile);
  return profile;
}

Future<String> _getValidAccessTokenImpl(ProfileAuthService self) async {
  try {
    await self._refreshIfNeeded();
    final token = await self._storage.read(AuthStorage.kAccessToken);
    if (token == null || token.isEmpty) {
      throw AuthException(message: 'Not logged in', code: 'NOT_LOGGED_IN');
    }
    return token;
  } on AppException catch (e, st) {
    self._logger.severe('Failed to get valid access token', e, st);
    rethrow;
  } catch (e, st) {
    self._logger.severe('Failed to get valid access token', e, st);
    throw AuthException(
      message: 'Failed to get valid access token',
      originalError: e,
      stackTrace: st,
    );
  }
}

Future<void> _logoutImpl(ProfileAuthService self) async {
  try {
    // A refresh still in flight would write fresh tokens back after the
    // delete below and silently resurrect the session.
    final inFlight = self._refreshInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (e) {
        // Its failure is irrelevant: the session is being dropped anyway.
        self._logger.fine('Ignoring in-flight refresh error during logout: $e');
      }
    }
    await self._storage.deleteAll();
    self._cachedProfile = null;
    self._grantedScopes = null;
    self._hasSessionCache = false;

    try {
      await getIt<LibraryService>().clearLibrary();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ProfileAuthService._libraryOwnerKey);
    } catch (e) {
      self._logger.warning('Failed to clear library on logout: $e');
    }

    self._notifyStateChanged();
  } catch (e, st) {
    self._logger.severe('Failed to logout', e, st);
    throw AuthException(
      message: 'Failed to logout',
      originalError: e,
      stackTrace: st,
    );
  }
}

Future<void> _persistGrantedScopesImpl(ProfileAuthService self, TokenResponse response) async {
  final granted = (response.scopes?.isNotEmpty ?? false)
      ? response.scopes!
      : AppConstants.oauthScopes;
  self._grantedScopes = List.unmodifiable(granted);
  try {
    await self._storage.write(AuthStorage.kGrantedScopes, granted.join(' '));
  } catch (e) {
    self._logger.warning('Could not record granted scopes: $e');
  }
}

Future<void> _persistTokensImpl(
  ProfileAuthService self,
  TokenResponse response,
) async {
  try {
    await self._storage.write(AuthStorage.kAccessToken, response.accessToken);
    if (response.refreshToken?.isNotEmpty ?? false) {
      await self._storage.write(
        AuthStorage.kRefreshToken,
        response.refreshToken,
      );
    }
    if (response.idToken?.isNotEmpty ?? false) {
      await self._storage.write(AuthStorage.kIdToken, response.idToken);
    }
    final exp = response.accessTokenExpirationDateTime
        ?.toUtc()
        .toIso8601String();
    if (exp != null) {
      self._logger.fine('Token expiration set to: $exp');
      await self._storage.write(AuthStorage.kAccessTokenExp, exp);
    } else {
      await self._storage.delete(AuthStorage.kAccessTokenExp);
    }
  } catch (e, st) {
    self._logger.severe('Failed to persist tokens', e, st);
    throw AuthException(
      message: 'Failed to persist tokens',
      originalError: e,
      stackTrace: st,
    );
  }
}

Future<TokenResponse?> _platformRefreshImpl(
  ProfileAuthService self,
  String refreshToken,
) {
  if (Platform.isWindows || Platform.isLinux) {
    return DesktopAuthHandler.refresh(
      clientId: self._clientId,
      redirectUri: self._redirectUri,
      tokenEndpoint: ProfileAuthService._tokenEndpoint,
      refreshToken: refreshToken,
      scopes: self._refreshScopes,
    );
  }
  return self._appAuth.token(
    TokenRequest(
      self._clientId,
      self._redirectUri,
      serviceConfiguration: self._serviceConfig,
      refreshToken: refreshToken,
      scopes: self._refreshScopes,
    ),
  );
}
