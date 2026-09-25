import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/app_bootstrap.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/palette/mb_palette.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_window_frame.dart';
import 'package:mangabaka_app/features/navigation/screens/animated_splash_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/login/browser_sign_in_prompt.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  await AppBootstrap.run();
  runApp(const MangaBakaApp());
}

/// The app root: chooses between onboarding and the main shell, holds the
/// splash overlay until it finishes, and owns the theme.
class MangaBakaApp extends StatefulWidget {
  const MangaBakaApp({super.key});

  @override
  State<MangaBakaApp> createState() => _MangaBakaAppState();
}

class _MangaBakaAppState extends State<MangaBakaApp> {
  final ThemeController _themes = ThemeController();

  /// Themes are rebuilt only when their inputs change — the palette and
  /// [SettingsManager.showTooltips], which is baked into the tooltip theme —
  /// rather than on every notification from the merged listenable, which
  /// fires for every setting there is.
  final Map<Brightness, (MbPalette, bool, ThemeData)> _cache = {};

  bool _showSplash = true;

  ThemeData _themeFor(MbPalette palette, bool showTooltips) {
    final cached = _cache[palette.brightness];
    if (cached != null && cached.$1 == palette && cached.$2 == showTooltips) {
      return cached.$3;
    }
    final theme = AppTheme.build(palette, showTooltips: showTooltips);
    _cache[palette.brightness] = (palette, showTooltips, theme);
    return theme;
  }

  MbPalette? _lastPalette;

  @override
  void initState() {
    super.initState();
    _themes.addListener(_onThemeChanged);
    _lastPalette = _themes.current;
    _syncWindowBackground(_themes.current);
  }

  @override
  void dispose() {
    _themes.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    final palette = _themes.current;
    if (palette == _lastPalette) return;
    _lastPalette = palette;
    AppTheme.applySystemOverlay(palette);
    _syncWindowBackground(palette);
  }

  /// Keeps the native desktop window's own background in step, so a resize
  /// never flashes the previous theme's colour behind the first frame.
  void _syncWindowBackground(MbPalette palette) {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;
    windowManager.setBackgroundColor(palette.background).ignore();
  }

  /// Checks GitHub for a newer release and, if found, shows the update dialog.
  /// Runs at most once per app launch.
  Future<void> _checkForAppUpdate() async {
    final service = getIt<UpdateService>();
    if (!service.shouldPrompt()) return;
    final release = await service.checkForUpdate();
    if (release == null) return;
    final context = AppConstants.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await UpdateDialog.show(context, release);
  }

  void _onSplashComplete({required bool isPastOnboarding}) {
    setState(() => _showSplash = false);
    // Only once the splash has cleared, and only for a user who is actually
    // in the app — an update prompt over onboarding is the wrong first thing
    // to see.
    if (isPastOnboarding) _checkForAppUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsManager(),
        _themes,
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final settings = SettingsManager();
        // Signing in implies onboarding is done, so a returning user who
        // cleared their settings does not get sent back through it.
        final isPastOnboarding =
            settings.hasCompletedOnboarding ||
            getIt<ProfileAuthService>().isLoggedIn;

        return ExcludeSemantics(
          // The Windows web-view component emits a platform accessibility
          // warning that has no fix at the widget level.
          excluding: Platform.isWindows,
          child: MaterialApp(
            navigatorKey: AppConstants.navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _themeFor(_themes.lightPalette, settings.showTooltips),
            darkTheme: _themeFor(_themes.darkPalette, settings.showTooltips),
            themeMode: _themes.materialThemeMode,
            builder: (context, child) => DesktopLayoutScope(
              child: DesktopWindowFrame(
                child: BrowserSignInPrompt(child: AppShortcuts(child: child!)),
              ),
            ),
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.overlayFor(_themes.current),
              child: Stack(
                children: [
                  if (isPastOnboarding)
                    MainScreen()
                  else
                    const OnboardingScreen(),
                  if (_showSplash)
                    AnimatedSplashOverlay(
                      onComplete: () =>
                          _onSplashComplete(isPastOnboarding: isPastOnboarding),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
