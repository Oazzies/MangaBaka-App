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

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggingService.setup();
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
        final hasCompletedOnboarding = SettingsManager().hasCompletedOnboarding;
        final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;

        final Widget content = (hasCompletedOnboarding || isLoggedIn)
            ? MainScreen()
            : const OnboardingScreen();

        return MaterialApp(
          navigatorKey: AppConstants.navigatorKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return AppShortcuts(child: child!);
          },
          theme: ThemeData(
            useMaterial3: true,
            tooltipTheme: TooltipThemeData(
              triggerMode: SettingsManager().showTooltips 
                  ? null 
                  : TooltipTriggerMode.manual,
              waitDuration: SettingsManager().showTooltips 
                  ? null 
                  : const Duration(days: 365),
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
            ),
            dividerColor: AppConstants.borderColor,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.dark,
              surface: AppConstants.primaryBackground,
              primary: AppConstants.accentColor,
              error: AppConstants.errorColor,
            ),
            tooltipTheme: TooltipThemeData(
              triggerMode: SettingsManager().showTooltips 
                  ? null 
                  : TooltipTriggerMode.manual,
              waitDuration: SettingsManager().showTooltips 
                  ? null 
                  : const Duration(days: 365),
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
            cardColor: AppConstants.secondaryBackground,
            dialogTheme: DialogThemeData(
              backgroundColor: AppConstants.secondaryBackground,
            ),
            dividerColor: AppConstants.borderColor,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
            ),
          ),
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
        );
      },
    );
  }
}
