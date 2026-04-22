import 'package:flutter/material.dart';

enum AppTheme { dark, light, monochrome }

/// App-wide constants for UI, API, and business logic
class AppConstants {
  // ============ API & Network ============
  static const String baseApiUrl = 'https://api.mangabaka.dev/v1';
  static const String authBaseUrl = 'https://mangabaka.org/auth/oauth2';
  static const String userAgent = 'BakaHyou/0.0 (oazziesmail@gmail.com)';
  static const int networkTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int rateLimitRetryDelaySeconds = 2;

  // ============ Pagination ============
  static const int defaultPageLimit = 20;
  static const int libraryPageLimit = 50; // API max
  static const double scrollThresholdPx = 100;

  // ============ UI Colors ============
  static Color primaryBackground = const Color(0xFF0a0a0a);
  static Color secondaryBackground = const Color(0xFF18181B);
  static Color tertiaryBackground = const Color(0xFF23232a);
  static Color accentColor = const Color(0xFF1b9f70);
  static Color primaryAccent = const Color(0xFF00301d);
  static Color borderColor = const Color(0xFF3f3f46);
  static Color successColor = const Color(0xFF81e6ca);
  static Color warningColor = const Color(0xFFffc83e);

  static void setAppTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        primaryBackground = const Color(0xFFF4F4F5);
        secondaryBackground = const Color(0xFFE4E4E7);
        tertiaryBackground = const Color(0xFFD4D4D8);
        accentColor = const Color(0xFF10b981);
        primaryAccent = const Color(0xFF047857);
        borderColor = const Color(0xFFA1A1AA);
        successColor = const Color(0xFF34d399);
        warningColor = const Color(0xFFfbbf24);
        break;
      case AppTheme.monochrome:
        primaryBackground = const Color(0xFF000000);
        secondaryBackground = const Color(0xFF111111);
        tertiaryBackground = const Color(0xFF222222);
        accentColor = const Color(0xFFE5E5E5);
        primaryAccent = const Color(0xFF404040);
        borderColor = const Color(0xFF333333);
        successColor = const Color(0xFFB3B3B3);
        warningColor = const Color(0xFF737373);
        break;
      case AppTheme.dark:
        primaryBackground = const Color(0xFF0a0a0a);
        secondaryBackground = const Color(0xFF18181B);
        tertiaryBackground = const Color(0xFF23232a);
        accentColor = const Color(0xFF1b9f70);
        primaryAccent = const Color(0xFF00301d);
        borderColor = const Color(0xFF3f3f46);
        successColor = const Color(0xFF81e6ca);
        warningColor = const Color(0xFFffc83e);
        break;
    }
  }

  // ============ UI Spacing ============
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;
  static const double cardRadius = 12.0;

  // ============ Animation ============
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);

  // ============ Library States ============
  static const Set<String> libraryStates = {
    'reading',
    'paused',
    'completed',
    'plan_to_read',
    'dropped',
    'rereading',
    'considering',
  };

  // ============ OAuth Scopes ============
  static const List<String> oauthScopes = [
    'openid',
    'profile',
    'library.read',
    'library.write',
    'offline_access',
  ];

  // ============ Storage Keys ============
  static const String prefixStorageKey = 'bakahyou_';
  static const String lastSyncKey = '${prefixStorageKey}last_sync';
  static const String userPreferencesKey = '${prefixStorageKey}preferences';

  // ============ Delays ============
  static const Duration debounceDelay = Duration(milliseconds: 500);
}
