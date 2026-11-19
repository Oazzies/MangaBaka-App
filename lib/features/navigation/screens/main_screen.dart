import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_banner.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';
import 'package:mangabaka_app/features/library/screens/library_screen.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/widgets/main_nav_rail.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/profile/screens/profile_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> mainScreenKey =
      GlobalKey<MainScreenState>();

  MainScreen({Key? key}) : super(key: key ?? mainScreenKey);

  static void setTabIndex(int index) {
    final desktop = DesktopShell.current;
    if (desktop != null) {
      desktop.select(index);
      return;
    }
    mainScreenKey.currentState?._onItemTapped(index);
  }

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  static final _logger = LoggingService.logger;

  static const double _tabletWidth = 600;

  late int _selectedIndex;

  /// Cached once so [IndexedStack] never recreates its children.
  late final List<Widget> _pages;

  /// Nested so the navbar stays visible while a pushed route is open.
  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Rebuilding the nested route on a tab change would drop its pushed stack.
  late final ValueNotifier<int> _selectedIndexNotifier;

  @override
  void initState() {
    super.initState();
    _selectedIndex = SettingsManager().defaultStartPage.index;
    _selectedIndexNotifier = ValueNotifier<int>(_selectedIndex);
    _pages = [
      const HomeScreen(),
      LibraryScreen(key: LibraryScreen.libraryScreenKey),
      _browsePage(),
      const NewsScreen(),
      const ProfileScreen(),
    ];
    _logger.info('MainScreen initialized with tab index: $_selectedIndex');
    if (_selectedIndex == NavTabs.browse) _autoFocusBrowseSearch();
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Decoded now: decoding on first paint made the settings preview pop in.
    precacheImage(
      AssetImage(mockSeries222.coverUrl),
      context,
    ).catchError((_) {});
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    super.dispose();
  }

  /// ExcludeSemantics on Windows: the web view triggers an accessibility warning.
  Widget _browsePage() {
    final browse = BrowseScreen(key: BrowseScreen.browseScreenKey);
    if (!Platform.isWindows) return browse;
    return ExcludeSemantics(child: browse);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    _logger.info('Tab switched to: $index');
    setState(() => _selectedIndex = index);
    _selectedIndexNotifier.value = index;
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (index == NavTabs.browse) _autoFocusBrowseSearch();
  }

  void _autoFocusBrowseSearch() {
    if (!SettingsManager().autoFocusBrowseSearch) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BrowseScreen.browseScreenKey.currentState?.enterSearchMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (DesktopLayout.isActive(context)) {
          return DesktopShell(
            initialIndex: _selectedIndex,
            onIndexChanged: (index) {
              _selectedIndex = index;
              _selectedIndexNotifier.value = index;
            },
          );
        }

        final isTablet = MediaQuery.sizeOf(context).width >= _tabletWidth;

        if (!isTablet) return _phoneLayout(l10n);
        return _tabletLayout(
          context,
          l10n,
          SettingsManager().landscapeAppBarPosition,
        );
      },
    );
  }

  Widget _phoneLayout(LocalizationService l10n) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: _withHealthBanner(_flatContent()),
      bottomNavigationBar: _bottomNav(l10n),
    );
  }

  Widget _tabletLayout(
    BuildContext context,
    LocalizationService l10n,
    LandscapeAppBarPosition position,
  ) {
    switch (position) {
      case LandscapeAppBarPosition.bottom:
        // Full-screen pushes: a nested navigator would only cost them height here.
        return Scaffold(
          backgroundColor: context.colors.background,
          body: _withHealthBanner(_flatContent()),
          bottomNavigationBar: _bottomNav(l10n),
        );

      case LandscapeAppBarPosition.right:
        return _railLayout(l10n, NavRailSide.right);

      case LandscapeAppBarPosition.left:
        return _railLayout(l10n, NavRailSide.left);
    }
  }

  Widget _railLayout(LocalizationService l10n, NavRailSide side) {
    final rail = MainNavRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      l10n: l10n,
      side: side,
    );
    final content = Expanded(child: _withHealthBanner(_nestedContent()));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Row(
        children: side == NavRailSide.left
            ? [rail, const NavRailDivider(), content]
            : [content, const NavRailDivider(), rail],
      ),
    );
  }

  Widget _bottomNav(LocalizationService l10n) => MbBottomNav(
    selectedIndex: _selectedIndex,
    onDestinationSelected: _onItemTapped,
    destinations: navDestinations(l10n),
  );

  Widget _flatContent() {
    return Stack(
      children: [
        IndexedStack(index: _selectedIndex, children: _pages),
        SyncProgressOverlay(libraryService: getIt<LibraryService>()),
      ],
    );
  }

  Widget _nestedContent() {
    return Stack(
      children: [
        Navigator(
          key: _contentNavigatorKey,
          onGenerateInitialRoutes: (_, __) => [
            PageRouteBuilder<void>(
              opaque: true,
              pageBuilder: (_, __, ___) => ValueListenableBuilder<int>(
                valueListenable: _selectedIndexNotifier,
                builder: (_, index, __) =>
                    IndexedStack(index: index, children: _pages),
              ),
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          ],
        ),
        SyncProgressOverlay(libraryService: getIt<LibraryService>()),
      ],
    );
  }

  Widget _withHealthBanner(Widget child) {
    return Column(
      children: [
        BackendHealthBanner(health: getIt<BackendHealthService>()),
        Expanded(child: child),
      ],
    );
  }
}
