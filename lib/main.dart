import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bakahyou/features/navigation/screens/main_screen.dart';
import 'package:bakahyou/features/navigation/screens/onboarding_screen.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  LoggingService.setup();
  await dotenv.load();
  setupServiceLocator();
  
  // Init auth and metadata independently from UI prefs — do sequentially since
  // SettingsManager may depend on auth state in the future.
  await getIt<ProfileAuthService>().init();
  await getIt<MetadataService>().init();

  // Theme, settings, and localization are independent — run in parallel.
  await Future.wait([
    ThemeManager().init(),
    SettingsManager().init(),
    LocalizationService().init(),
  ]);

  // Set initial system UI style
  _updateSystemUI(ThemeManager().isDarkMode);

  runApp(const BakaHyouApp());
  
  // Remove the splash screen after the app has started
  FlutterNativeSplash.remove();
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

class BakaHyouApp extends StatelessWidget {
  const BakaHyouApp({super.key});

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
        _updateSystemUI(isDark);

        final hasCompletedOnboarding = SettingsManager().hasCompletedOnboarding;
        final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;
        
        return MaterialApp(
          title: AppConstants.appName,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.light,
              surface: AppConstants.primaryBackground,
              primary: AppConstants.accentColor,
              error: AppConstants.errorColor,
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
            cardColor: AppConstants.secondaryBackground,
            dialogBackgroundColor: AppConstants.secondaryBackground,
            dividerColor: AppConstants.borderColor,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              modalBackgroundColor: AppConstants.secondaryBackground,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.dark,
              surface: AppConstants.primaryBackground,
              primary: AppConstants.accentColor,
              error: AppConstants.errorColor,
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
            cardColor: AppConstants.secondaryBackground,
            dialogBackgroundColor: AppConstants.secondaryBackground,
            dividerColor: AppConstants.borderColor,
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: AppConstants.secondaryBackground,
              modalBackgroundColor: AppConstants.secondaryBackground,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppConstants.primaryBackground,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          themeMode: currentThemeMode,
          home: (hasCompletedOnboarding || isLoggedIn)
              ? MainScreen() 
              : const OnboardingScreen(),
        );
      },
    );
  }
}
