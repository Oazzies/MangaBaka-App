import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/build_error_fallback.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_service.dart';
import 'package:window_manager/window_manager.dart';

/// Order matters: error handlers go in before anything that can throw.
class AppBootstrap {
  AppBootstrap._();

  /// minimumSize includes the native frame; this keeps the client area >= [DesktopLayout.minWidth].
  static const double _windowFrameMargin = 64;

  /// Never below the desktop layout's width, so the window can't shrink into the mobile layouts.
  static const Size _minWindowSize = Size(
    DesktopLayout.minWidth + _windowFrameMargin,
    700,
  );

  static Future<void> run() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();

    await _configureDesktopWindow();

    // Held until the app's own splash overlay takes over, so no bare frame shows between them.
    FlutterNativeSplash.preserve(widgetsBinding: binding);

    await LoggingService.setup();
    _installErrorHandlers();

    // A missing .env must not abort startup; sign-in then reports MISSING_CONFIG.
    try {
      await dotenv.load(isOptional: true);
    } catch (e, st) {
      LoggingService.logger.severe('Could not load .env', e, st);
    }
    setupServiceLocator();

    // Auth first: the metadata fetch and initial library sync read the session it restores.
    await getIt<ProfileAuthService>().init();
    await getIt<MetadataService>().init();

    // Each guarded so bad preferences or a bad language pack fall back instead of a blank window.
    await Future.wait([
      SettingsManager().init().catchError((Object e, StackTrace st) {
        LoggingService.logger.severe('Settings failed to load', e, st);
      }),
      LocalizationService().init().catchError((Object e, StackTrace st) {
        LoggingService.logger.severe('Localization failed to load', e, st);
      }),
    ]);

    ThemeController().init();
    AppTheme.applySystemOverlay(ThemeController().current);

    // Last: deep links need settings (for the toggle) and services (to fetch series).
    await getIt<DeepLinkService>().init();
  }

  static Future<void> _configureDesktopWindow() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      // The Windows runner enforces its own DPI-exact minimum (windows/runner/flutter_window.cpp).
      minimumSize: Platform.isWindows ? null : _minWindowSize,
      titleBarStyle: Platform.isWindows
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: !Platform.isWindows,
    );

    // Not awaited: it resolves only once the window is shown, after the first frame.
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static void _installErrorHandlers() {
    BuildErrorFallback.install();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      LoggingService.logger.severe(
        'Flutter Error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      LoggingService.logger.severe('Unhandled Platform Error', error, stack);
      return true;
    };
  }
}
