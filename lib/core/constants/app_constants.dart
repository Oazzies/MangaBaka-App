import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'MangaBaka';
  static const String appVersion = '0.4.1';
  static const String baseApiUrl = 'https://api.mangabaka.org/v1';
  static const String baseApiUrlV2 = 'https://api.mangabaka.org/v2';

  static const String githubOwner = 'Oazzies';
  static const String githubRepo = 'MangaBaka-App';
  static const String githubReleasesApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases';
  static const String authBaseUrl = 'https://mangabaka.org/auth/oauth2';
  static const String userAgent =
      '$appName/$appVersion (oazziesmail@gmail.com)';
  static const int networkTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int rateLimitRetryDelaySeconds = 5;

  static const int defaultPageLimit = 20;
  static const int libraryPageLimit = 100; // entries per page (API max)
  static const int libraryMaxPages = 10000; // API max pages
  static const double scrollThresholdPx = 100;

  // Colours are not constants: they come from the active theme. Read them
  // with `context.colors.<token>` (lib/core/theme/theme_context.dart).

  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;
  static const double cardRadius = 20.0;
  static const double largeRadius = 24.0;
  static const double denseRadius = 14.0;
  static const double pillRadius = 999.0;

  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  static const Set<String> libraryStates = {
    'reading',
    'paused',
    'completed',
    'plan_to_read',
    'dropped',
    'rereading',
    'considering',
  };

  /// Scopes every session has asked for since sign-in first shipped.
  static const List<String> baseOauthScopes = [
    'openid',
    'profile',
    'library.read',
    'library.write',
    'offline_access',
  ];

  /// Scopes Stacks needs (added to MangaBaka 2026-10-13). A session from
  /// before then lacks them until the user signs in again.
  static const List<String> stackOauthScopes = ['stack.read', 'stack.write'];

  /// What a new sign-in asks for.
  static const List<String> oauthScopes = [
    ...baseOauthScopes,
    ...stackOauthScopes,
  ];

  static const String prefixStorageKey = 'mangabaka_app_';
  static const String libraryCursorKey =
      '${prefixStorageKey}library_changes_cursor';
  static const String lastSyncKey = '${prefixStorageKey}last_sync';
  static const String userPreferencesKey = '${prefixStorageKey}preferences';

  static const Duration debounceDelay = Duration(milliseconds: 500);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
