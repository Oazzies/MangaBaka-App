import 'package:flutter/material.dart';

import 'package:mangabaka_app/core/theme/app_theme_colors.dart';
export 'package:mangabaka_app/core/theme/app_theme_colors.dart' show AppTheme;

class AppConstants {
  static const String appName = 'MangaBaka';
  static const String appVersion = '0.2.4';
  static const String baseApiUrl = 'https://api.mangabaka.dev/v1';

  // GitHub repository used by the in-app update system.
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

  static Color primaryBackground = const Color(0xFF14120E);
  static Color secondaryBackground = const Color(0xFF1B1813);
  static Color tertiaryBackground = const Color(0xFF2A261E);
  static Color accentColor = const Color(0xFF1b9f70);
  static Color primaryAccent = const Color(0xFF15875E);
  static Color borderColor = const Color(0xFF2C2820);
  static Color successColor = const Color(0xFF81e6ca);
  static Color warningColor = const Color(0xFFffc83e);
  static Color errorColor = const Color(0xFFef4444);
  static Color infoColor = const Color(0xFF3b82f6);
  static Color textColor = const Color(0xFFF1ECE2);
  static Color textMutedColor = const Color(0xFF8B8474);

  static void setAppTheme(AppTheme theme, bool isDark) {
    AppThemeColors.applyTheme(theme, isDark);
  }

  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double largeRadius = 12.0;
  static const double denseRadius = 8.0;
  static const double pillRadius = 999.0;

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

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

  static const List<String> oauthScopes = [
    'openid',
    'profile',
    'library.read',
    'library.write',
    'offline_access',
  ];

  static const String prefixStorageKey = 'mangabaka_app_';
  static const String lastSyncKey = '${prefixStorageKey}last_sync';
  static const String userPreferencesKey = '${prefixStorageKey}preferences';

  static const Duration debounceDelay = Duration(milliseconds: 500);

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
