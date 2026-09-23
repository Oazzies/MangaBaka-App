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
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:window_manager/window_manager.dart';

/// Everything that has to happen before the first frame.
///
/// Kept apart from `main.dart` so the entry point reads as a sequence rather
/// than as three hundred lines of setup, and so the order — which genuinely
/// matters, since error handling has to be installed before anything that can
/// throw — is visible in one place.
class AppBootstrap {
  AppBootstrap._();

  /// The OS window manager applies [WindowOptions.minimumSize] to the whole
  /// window, including its native frame, while Flutter measures only the
  /// client area inside that frame. This margin absorbs the frame so the
  /// client width stays at or above [DesktopLayout.minWidth] even at the
  /// smallest size and on scaled displays.
  static const double _windowFrameMargin = 64;

  /// Smallest the macOS and Linux window may be dragged to. Pinned to the
  /// width the desktop (sidebar) layout needs, so the window can never shrink
  /// into the mobile layouts — the desktop app is always the sidebar
  /// presentation. Windows gets the same limit from its runner.
  static const Size _minWindowSize = Size(
    DesktopLayout.minWidth + _windowFrameMargin,
    700,
  );

  static Future<void> run() async {
    final binding = WidgetsFlutterBinding.ensureInitialized();

    await _configureDesktopWindow();

    // Hold the native splash until the app's own splash overlay takes over,
    // so there is no bare frame between them.
    FlutterNativeSplash.preserve(widgetsBinding: binding);

    await LoggingService.setup();
    _installErrorHandlers();

    await dotenv.load();
    setupServiceLocator();

    // Auth first: the metadata fetch and the initial library sync both read
    // the session it restores.
    await getIt<ProfileAuthService>().init();
    await getIt<MetadataService>().init();

    // Independent of each other, so they overlap.
    await Future.wait([
      SettingsManager().init(),
      LocalizationService().init(),
    ]);

    ThemeController().init();
    AppTheme.applySystemOverlay(ThemeController().current);
  }

  static Future<void> _configureDesktopWindow() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    await windowManager.ensureInitialized();

    // On Windows, hide the native title bar so the app can draw its own
    // custom styled title bar and window control buttons.
    final windowOptions = WindowOptions(
      // The Windows runner enforces its own, DPI-exact minimum (see
      // windows/runner/flutter_window.cpp).
      minimumSize: Platform.isWindows ? null : _minWindowSize,
      titleBarStyle:
          Platform.isWindows ? TitleBarStyle.hidden : TitleBarStyle.normal,
      windowButtonVisibility: !Platform.isWindows,
    );

    // Deliberately not awaited: it resolves only once the window is shown,
    // which happens after the first frame.
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Routes both error channels into the log.
  ///
  /// Without these, an error in a callback or an unawaited future is printed
  /// to the console and lost — the log is the only diagnostic available from
  /// a user's device.
  static void _installErrorHandlers() {
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
      // Handled: reported to the log rather than crashing the app.
      return true;
    };
  }
}
