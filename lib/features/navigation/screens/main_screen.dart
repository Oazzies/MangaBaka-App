import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/library/screens/library_screen.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/profile/screens/profile_screen.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();
  
  MainScreen({Key? key}) : super(key: key ?? mainScreenKey);

  static void setTabIndex(int index) {
    mainScreenKey.currentState?._onItemTapped(index);
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  static final _logger = LoggingService.logger;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = SettingsManager().defaultStartPage.index;
    _logger.info('MainScreen initialized with tab index: $_selectedIndex');
  }

  // Keep pages alive across tab switches with IndexedStack
  final List<Widget> _pages = const [
    HomeScreen(),
    LibraryScreen(),
    BrowseScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _logger.info('Tab switched to: $index');
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.secondaryBackground,
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              const SyncProgressOverlay(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: AppConstants.secondaryBackground,
                labelTextStyle: WidgetStateProperty.all(
                  TextStyle(color: AppConstants.textColor, fontSize: 12),
                ),
                iconTheme: WidgetStateProperty.all(
                  IconThemeData(color: AppConstants.textColor, size: 28),
                ),
              ),
              child: NavigationBar(
                backgroundColor: AppConstants.secondaryBackground,
                indicatorColor: AppConstants.accentColor,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: l10n.translate("home"),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.library_books_outlined),
                    selectedIcon: const Icon(Icons.library_books),
                    label: l10n.translate("library"),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    label: l10n.translate("browse"),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon: const Icon(Icons.article),
                    label: l10n.translate("news"),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: l10n.translate("profile"),
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
