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
  await getIt<ProfileAuthService>().init();
  await getIt<MetadataService>().init();
  
  await ThemeManager().init();
  await SettingsManager().init();
  await LocalizationService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BakaHyouApp());
  
  // Remove the splash screen after the app has started
  FlutterNativeSplash.remove();
}

class BakaHyouApp extends StatelessWidget {
  const BakaHyouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final currentThemeMode = ThemeManager().currentThemeMode;
        
        return MaterialApp(
          title: 'BakaHyou',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryAccent,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppConstants.primaryBackground,
          ),
          themeMode: currentThemeMode,
          home: SettingsManager().hasCompletedOnboarding 
              ? MainScreen() 
              : OnboardingScreen(),
        );
      },
    );
  }
}
