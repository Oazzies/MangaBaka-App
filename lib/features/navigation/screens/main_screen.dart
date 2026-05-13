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
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

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
        final size = MediaQuery.of(context).size;
        final isTablet = size.width >= 600;
        final l10n = LocalizationService();

        Widget content = Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            const SyncProgressOverlay(),
          ],
        );

        if (isTablet) {
          return Scaffold(
            backgroundColor: AppConstants.secondaryBackground,
            body: Row(
              children: [
                Container(
                  width: 96,
                  color: AppConstants.secondaryBackground,
                  child: SafeArea(
                    right: false,
                    child: NavigationRail(
                      backgroundColor: AppConstants.secondaryBackground,
                      indicatorColor: AppConstants.accentColor.withValues(alpha: 0.15),
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.all,
                      unselectedLabelTextStyle: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      selectedLabelTextStyle: TextStyle(
                        color: AppConstants.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedIconTheme: IconThemeData(
                        color: AppConstants.textColor.withValues(alpha: 0.5),
                        size: 26,
                      ),
                      selectedIconTheme: IconThemeData(
                        color: AppConstants.accentColor,
                        size: 26,
                      ),
                      leading: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              'assets/mangabaka512.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: Text(l10n.translate("home")),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_books_outlined),
                          selectedIcon: const Icon(Icons.library_books),
                          label: Text(l10n.translate("library")),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.explore_outlined),
                          selectedIcon: const Icon(Icons.explore),
                          label: Text(l10n.translate("browse")),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.article_outlined),
                          selectedIcon: const Icon(Icons.article),
                          label: Text(l10n.translate("news")),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.person_outline),
                          selectedIcon: const Icon(Icons.person),
                          label: Text(l10n.translate("profile")),
                        ),
                      ],
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: WidgetUtils.tooltip(
                              message: l10n.translate("settings"),
                              child: IconButton(
                                icon: const Icon(Icons.settings_outlined),
                                selectedIcon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                  );
                                },
                                color: AppConstants.textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppConstants.secondaryBackground,
          body: content,
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
