import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_banner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_screen.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_home_screen.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_library_screen.dart';
import 'package:mangabaka_app/desktop/screens/news/desktop_news_screen.dart';
import 'package:mangabaka_app/desktop/screens/profile/desktop_profile_screen.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_sidebar.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Implemented by desktop pages that can reload their content, so Ctrl+R
/// works wherever keyboard focus happens to be.
abstract interface class DesktopRefreshable {
  Future<void> refresh();
}

/// The desktop app frame: a permanent sidebar and a content area with its own
/// navigator.
///
/// Pushed routes — series detail, results lists, logs — open inside the
/// content area, so the sidebar stays put and one click on it returns to a
/// destination. Pages are built once and kept alive in an [IndexedStack], as
/// on mobile, so each keeps its scroll position and loaded data.
class DesktopShell extends StatefulWidget {
  static final GlobalKey<DesktopShellState> shellKey =
      GlobalKey<DesktopShellState>();

  final int initialIndex;

  /// Reports destination changes back to the owner, which keeps the index
  /// across a switch to the mobile layout and back.
  final ValueChanged<int>? onIndexChanged;

  DesktopShell({required this.initialIndex, this.onIndexChanged})
    : super(key: shellKey);

  /// The mounted shell, or null when the mobile layout is showing.
  static DesktopShellState? get current => shellKey.currentState;

  @override
  State<DesktopShell> createState() => DesktopShellState();
}

class DesktopShellState extends State<DesktopShell> {
  static final _logger = LoggingService.logger;

  static const int settingsIndex = DesktopSidebar.settingsIndex;

  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();

  final List<GlobalKey> _pageKeys = [
    DesktopHomeScreen.stateKey,
    DesktopLibraryScreen.stateKey,
    DesktopBrowseScreen.stateKey,
    DesktopNewsScreen.stateKey,
    DesktopProfileScreen.stateKey,
    DesktopSettingsScreen.stateKey,
  ];

  late final List<Widget> _pages;
  late final ValueNotifier<int> _index;

  /// Null follows the window width; a click on the toggle pins it.
  bool? _collapsedOverride;

  int get selectedIndex => _index.value;

  @override
  void initState() {
    super.initState();
    _index = ValueNotifier(widget.initialIndex.clamp(0, settingsIndex));
    _pages = [
      DesktopHomeScreen(key: DesktopHomeScreen.stateKey),
      DesktopLibraryScreen(key: DesktopLibraryScreen.stateKey),
      DesktopBrowseScreen(key: DesktopBrowseScreen.stateKey),
      DesktopNewsScreen(key: DesktopNewsScreen.stateKey),
      DesktopProfileScreen(key: DesktopProfileScreen.stateKey),
      DesktopSettingsScreen(key: DesktopSettingsScreen.stateKey),
    ];
  }

  @override
  void dispose() {
    _index.dispose();
    super.dispose();
  }

  // ─── Public surface ──────────────────────────────────────────────────────

  /// Shows destination [index] (0–4 for the tabs, [settingsIndex] for
  /// settings), unwinding anything pushed over the current one.
  void select(int index) {
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (_index.value == index) return;
    _logger.info('Desktop destination switched to: $index');
    setState(() => _index.value = index);
    if (index < navItems.length) widget.onIndexChanged?.call(index);
  }

  void openSettings() => select(settingsIndex);

  /// Jumps to search: the library's own field when the library is showing,
  /// Browse's otherwise.
  void focusSearch() {
    if (_index.value == NavTabs.library &&
        _contentNavigatorKey.currentState?.canPop() != true) {
      DesktopLibraryScreen.stateKey.currentState?.focusSearch();
      return;
    }
    select(NavTabs.browse);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DesktopBrowseScreen.stateKey.currentState?.focusSearch();
    });
  }

  /// Pops the content area's top route. Returns false when it is already at
  /// a destination root.
  bool popContent() {
    final navigator = _contentNavigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) return false;
    navigator.maybePop();
    return true;
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final collapsed =
        _collapsedOverride ?? width < DesktopTokens.sidebarAutoCollapseWidth;
    final sidebarWidth = collapsed
        ? DesktopTokens.sidebarCollapsedWidth
        : DesktopTokens.sidebarWidth;

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) => Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) {
              focusSearch();
              return null;
            },
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) {
              final state = _pageKeys[_index.value].currentState;
              if (state is DesktopRefreshable) {
                (state as DesktopRefreshable).refresh();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: context.colors.background,
          // The content is laid out once, at its final position, while the
          // sidebar animates across the top of it. Animating the sidebar in a
          // Row instead resized the content area on every frame of the
          // transition, re-laying out whole grids and carousels ~20 times per
          // toggle — that was the lag.
          body: Stack(
            children: [
              Positioned.fill(
                left: sidebarWidth,
                child: Column(
                  children: [
                    const BackendHealthBanner(),
                    Expanded(child: _content()),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: DesktopSidebar(
                    selectedIndex: _index.value,
                    onSelected: select,
                    onSearch: focusSearch,
                    collapsed: collapsed,
                    onToggleCollapsed: () =>
                        setState(() => _collapsedOverride = !collapsed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        Navigator(
          key: _contentNavigatorKey,
          onGenerateInitialRoutes: (_, __) => [
            PageRouteBuilder<void>(
              opaque: true,
              pageBuilder: (_, __, ___) => ValueListenableBuilder<int>(
                valueListenable: _index,
                builder: (_, index, __) =>
                    IndexedStack(index: index, children: _pages),
              ),
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          ],
        ),
        const SyncProgressOverlay(),
      ],
    );
  }
}
