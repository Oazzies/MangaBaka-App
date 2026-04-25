import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/screens/browse_screen.dart';
import 'package:bakahyou/features/library/screens/library_screen.dart';
import 'package:bakahyou/features/news/screens/news_screen.dart';
import 'package:bakahyou/features/profile/screens/profile_screen.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

import 'package:bakahyou/utils/localization/localization_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = SettingsManager().defaultStartPage.index;
  }

  // Keep pages alive across tab switches with IndexedStack
  List<Widget> get _pages => [
    const Placeholder(),
    LibraryScreen(),
    BrowseScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.secondaryBackground,
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
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
