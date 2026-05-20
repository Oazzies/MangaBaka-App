import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/animated_splash_screen.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/app_shortcuts.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.setMinimumSize(const Size(500, 700));
    });
  }

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await LoggingService.setup();

  // Handle Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LoggingService.logger.severe(
      'Flutter Error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  // Handle platform/async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggingService.logger.severe('Unhandled Platform Error', error, stack);
    return true; // Error has been handled
  };

  await dotenv.load();
  setupServiceLocator();

  await getIt<ProfileAuthService>().init();
  await getIt<MetadataService>().init();

  await Future.wait([
    ThemeManager().init(),
    SettingsManager().init(),
    LocalizationService().init(),
  ]);

  _updateSystemUI(ThemeManager().isDarkMode);

  runApp(const MangaBakaApp());
}

void _updateSystemUI(bool isDarkMode) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
}

class MangaBakaApp extends StatefulWidget {
  const MangaBakaApp({super.key});

  @override
  State<MangaBakaApp> createState() => _MangaBakaAppState();
}

class _MangaBakaAppState extends State<MangaBakaApp> {
  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;
  bool? _lastShowTooltips;
  AppTheme? _lastTheme;
  bool? _lastIsDarkMode;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeManager(),
        SettingsManager(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final currentThemeMode = ThemeManager().currentThemeMode;
        final isDark = ThemeManager().isDarkMode;
        final currentTheme = ThemeManager().currentTheme;
        final hasCompletedOnboarding = SettingsManager().hasCompletedOnboarding;
        final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;
        final showTooltips = SettingsManager().showTooltips;

        if (_cachedLightTheme == null ||
            _cachedDarkTheme == null ||
            _lastShowTooltips != showTooltips ||
            _lastTheme != currentTheme ||
            _lastIsDarkMode != isDark) {
          _lastShowTooltips = showTooltips;
          _lastTheme = currentTheme;
          _lastIsDarkMode = isDark;

          // Re-apply the current theme palette values to AppConstants before rebuilding ThemeData
          AppConstants.setAppTheme(currentTheme, isDark);

          _cachedLightTheme = ThemeData(
            useMaterial3: true,
            tooltipTheme: TooltipThemeData(
              triggerMode: showTooltips ? null : TooltipTriggerMode.manual,
              waitDuration: showTooltips ? null : const Duration(days: 365),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.light,
              surface: AppConstants.primaryBackground,
              primary: AppConstants.accentColor,
              error: AppConstants.errorColor,
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
            cardColor: AppConstants.secondaryBackground,
            dialogTheme: DialogThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
            ),
            dividerColor: Colors.transparent,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.largeRadius),
                ),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppConstants.tertiaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.largeRadius),
              ),
              color: AppConstants.secondaryBackground,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              elevation: 0,
              indicatorColor: AppConstants.accentColor.withValues(alpha: 0.15),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconTheme: WidgetStateProperty.all(
                IconThemeData(color: AppConstants.textColor, size: 26),
              ),
            ),
            navigationRailTheme: NavigationRailThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              indicatorColor: AppConstants.accentColor.withValues(alpha: 0.15),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              labelType: NavigationRailLabelType.all,
              unselectedLabelTextStyle: TextStyle(
                color: AppConstants.textMutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              selectedLabelTextStyle: TextStyle(
                color: AppConstants.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          _cachedDarkTheme = ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.dark,
              surface: AppConstants.primaryBackground,
              primary: AppConstants.accentColor,
              error: AppConstants.errorColor,
            ),
            tooltipTheme: TooltipThemeData(
              triggerMode: showTooltips ? null : TooltipTriggerMode.manual,
              waitDuration: showTooltips ? null : const Duration(days: 365),
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
            cardColor: AppConstants.secondaryBackground,
            dialogTheme: DialogThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
            ),
            dividerColor: Colors.transparent,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.largeRadius),
                ),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppConstants.tertiaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.largeRadius),
              ),
              color: AppConstants.secondaryBackground,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              elevation: 0,
              indicatorColor: AppConstants.accentColor.withValues(alpha: 0.15),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconTheme: WidgetStateProperty.all(
                IconThemeData(color: AppConstants.textColor, size: 26),
              ),
            ),
            navigationRailTheme: NavigationRailThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              indicatorColor: AppConstants.accentColor.withValues(alpha: 0.15),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              labelType: NavigationRailLabelType.all,
              unselectedLabelTextStyle: TextStyle(
                color: AppConstants.textMutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              selectedLabelTextStyle: TextStyle(
                color: AppConstants.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final Widget content = (hasCompletedOnboarding || isLoggedIn)
            ? MainScreen()
            : const OnboardingScreen();

        return ExcludeSemantics(
          excluding: Platform.isWindows,
          child: MaterialApp(
            navigatorKey: AppConstants.navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AppShortcuts(child: child!);
            },
            theme: _cachedLightTheme,
            darkTheme: _cachedDarkTheme,
            themeMode: currentThemeMode,
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              ),
              child: Stack(
                children: [
                  content,
                  if (_showSplash)
                    AnimatedSplashOverlay(
                      onComplete: () {
                        setState(() {
                          _showSplash = false;
                        });
                      },
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
