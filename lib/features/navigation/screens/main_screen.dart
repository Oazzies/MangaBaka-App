import 'dart:io';
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

// ---------------------------------------------------------------------------
// Nav destination data
// ---------------------------------------------------------------------------

@immutable
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
}

const _navItems = [
  _NavItem(icon: Icons.home_outlined,         selectedIcon: Icons.home,          labelKey: 'home'),
  _NavItem(icon: Icons.library_books_outlined, selectedIcon: Icons.library_books, labelKey: 'library'),
  _NavItem(icon: Icons.explore_outlined,       selectedIcon: Icons.explore,       labelKey: 'browse'),
  _NavItem(icon: Icons.article_outlined,       selectedIcon: Icons.article,       labelKey: 'news'),
  _NavItem(icon: Icons.person_outline,         selectedIcon: Icons.person,        labelKey: 'profile'),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> mainScreenKey =
      GlobalKey<MainScreenState>();

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

  // Cached once so IndexedStack never recreates its children.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = SettingsManager().defaultStartPage.index;
    // BrowseScreen needs ExcludeSemantics on Windows to suppress a platform
    // accessibility warning triggered by the web-view component.
    _pages = [
      const HomeScreen(),
      const LibraryScreen(),
      Platform.isWindows
          ? const ExcludeSemantics(child: BrowseScreen())
          : const BrowseScreen(),
      const NewsScreen(),
      const ProfileScreen(),
    ];
    _logger.info('MainScreen initialized with tab index: $_selectedIndex');
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _logger.info('Tab switched to: $index');
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final isTablet = MediaQuery.of(context).size.width >= 600;
        final l10n = LocalizationService();

        final content = Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            const SyncProgressOverlay(),
          ],
        );

        if (isTablet) {
          return _buildTabletLayout(context, content, l10n);
        }
        return _buildPhoneLayout(content, l10n);
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context, Widget content, LocalizationService l10n) {
    return Scaffold(
      backgroundColor: AppConstants.secondaryBackground,
      body: Row(
        children: [
          Container(
            width: 88,
            color: AppConstants.secondaryBackground,
            child: SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                leading: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.denseRadius),
                      ),
                      child: Image.asset(
                        'assets/mangabaka512.png',
                        width: 36,
                        height: 36,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
                destinations: _navItems
                    .map((item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(l10n.translate(item.labelKey)),
                        ))
                    .toList(),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: WidgetUtils.tooltip(
                        message: l10n.translate('settings'),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          color: AppConstants.textMutedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            color: AppConstants.borderColor.withValues(alpha: 0.3),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(Widget content, LocalizationService l10n) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: l10n.translate(item.labelKey),
                ))
            .toList(),
      ),
    );
  }
}
