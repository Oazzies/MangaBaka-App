import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bakahyou/features/navigation/screens/main_screen.dart';
import 'package:bakahyou/utils/services/logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggingService.setup();
  await dotenv.load();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const BakaHyouApp());
}

class BakaHyouApp extends StatelessWidget {
  const BakaHyouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BakaHyou',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00301d)),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF00301d),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const MainScreen(),
    );
  }
}
