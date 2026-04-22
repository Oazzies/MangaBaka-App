import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bakahyou/features/navigation/screens/main_screen.dart';
import 'package:bakahyou/utils/services/logging_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.setup();
  await dotenv.load();
  setupServiceLocator();
  
  await ThemeManager().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BakaHyouApp());
}

class BakaHyouApp extends StatelessWidget {
  const BakaHyouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final theme = ThemeManager().currentTheme;
        final isLight = theme == AppTheme.light;
        
        return MaterialApp(
          key: ValueKey(theme),
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
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          home: const MainScreen(),
        );
      },
    );
  }
}
