import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_banner.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/features/home/screens/home_screen.dart';
import 'package:mangabaka_app/features/library/screens/library_screen.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/widgets/main_nav_rail.dart';
import 'package:mangabaka_app/features/navigation/widgets/main_top_nav_bar.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/profile/screens/profile_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The app shell: the five top-level tabs and whichever navigation chrome the
/// window shape and the user's preference call for.
///
/// Pages are built once and kept in an [IndexedStack], so switching tabs
/// preserves each one's scroll position and in-flight work.
class MainScreen extends StatefulWidget {
  static final GlobalKey<MainScreenState> mainScreenKey =
      GlobalKey<MainScreenState>();

  MainScreen({Key? key}) : super(key: key ?? mainScreenKey);

  /// Switches tabs from anywhere — used when a chip on one screen starts a
  /// search that belongs on another.
  static void setTabIndex(int index) {
    final desktop = DesktopShell.current;
    if (desktop != null) {
      desktop.select(index);
      return;
    }
    mainScreenKey.currentState?._onItemTapped(index);
  }

  /// Whether the top nav bar is hosting the current tab's search field, in
  /// which case that screen must not draw its own.
  ///
  /// Only the top position has a horizontal run to put a field in, and only
  /// past this width is there room for it beside the tabs.
  static bool showSearchBarInTopNavBar(BuildContext context) {
    if (MediaQuery.orientationOf(context) != Orientation.landscape) {
      return false;
    }
    if (SettingsManager().landscapeAppBarPosition !=
        LandscapeAppBarPosition.top) {
      return false;
    }
    return MediaQuery.sizeOf(context).width >= _searchInNavBarWidth;
  }

  static const double _searchInNavBarWidth = 1050;

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  static final _logger = LoggingService.logger;

  /// Above this width the tablet layouts apply, with the rail or top bar the
  /// user has chosen; below it, the phone layout's bottom bar.
  static const double _tabletWidth = 600;

  late int _selectedIndex;

  /// Cached once so [IndexedStack] never recreates its children.
  late final List<Widget> _pages;

  /// Nested navigator for non-bottom landscape layouts, so the navbar stays
  /// visible while series detail (or any pushed route) is open.
  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Drives the nested navigator's [IndexedStack] without rebuilding the route
  /// itself, which would drop the pushed stack on every tab change.
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
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // The list-style preview in settings shows a bundled sample cover. Decoding
    // it on first paint is what made the preview pop in, so decode it now and
    // let the preview hit the image cache synchronously.
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

  /// BrowseScreen needs ExcludeSemantics on Windows to suppress a platform
  /// accessibility warning triggered by the web-view component.
  Widget _browsePage() {
    final browse = BrowseScreen(key: BrowseScreen.browseScreenKey);
    if (!Platform.isWindows) return browse;
    return ExcludeSemantics(child: browse);
  }

  /// Rebuilds the chrome so the top nav bar can pick up a search field from a
  /// screen that has only just mounted.
  void updateTopNavBar() {
    if (!mounted) return;
    setState(() {});
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    _logger.info('Tab switched to: $index');
    setState(() => _selectedIndex = index);
    _selectedIndexNotifier.value = index;
    // Pop series detail (or any nested route) so switching tabs always
    // returns to the tab root within the nested navigator.
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        // A wide desktop window gets the desktop presentation layer; the
        // phone and tablet layouts below are for everything else.
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

  // ─── Layouts ─────────────────────────────────────────────────────────────

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
      case LandscapeAppBarPosition.top:
        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: MainTopNavBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            l10n: l10n,
            showSearchField: MainScreen.showSearchBarInTopNavBar(context),
          ),
          body: _withHealthBanner(_nestedContent()),
        );

      case LandscapeAppBarPosition.bottom:
        // The bottom bar is the one position that keeps full-screen pushes:
        // it already sits out of the way, so a nested navigator would only
        // cost the pushed route its full height.
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

  // ─── Content ─────────────────────────────────────────────────────────────

  /// The pages with no navigator of their own — routes pushed from here cover
  /// the whole window, including the navigation chrome.
  Widget _flatContent() {
    return Stack(
      children: [
        IndexedStack(index: _selectedIndex, children: _pages),
        const SyncProgressOverlay(),
      ],
    );
  }

  /// The pages inside a nested [Navigator], so routes pushed from within (for
  /// example series detail) stay in the content area and the rail or top bar
  /// remains visible beside them.
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
              // The tab root never animates in; only routes pushed on top of
              // it do.
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          ],
        ),
        const SyncProgressOverlay(),
      ],
    );
  }

  /// The backend-health bar sits above whatever page is showing — and above
  /// the nested navigator, so it stays put while series detail is open —
  /// without pushing the bottom nav off screen.
  Widget _withHealthBanner(Widget child) {
    return Column(
      children: [
        const BackendHealthBanner(),
        Expanded(child: child),
      ],
    );
  }
}
