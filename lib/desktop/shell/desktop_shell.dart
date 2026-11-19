import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_banner.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/active_page_stack.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_screen.dart';
import 'package:mangabaka_app/desktop/screens/home/desktop_home_screen.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_library_screen.dart';
import 'package:mangabaka_app/desktop/screens/news/desktop_news_screen.dart';
import 'package:mangabaka_app/desktop/screens/profile/desktop_profile_screen.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/desktop/shell/desktop_sidebar.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/widgets/sync_progress_overlay.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/shared/widgets/app_shortcuts.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_shell_history_part.dart';

abstract interface class DesktopRefreshable {
  Future<void> refresh();
}

class DesktopShell extends StatefulWidget {
  static final GlobalKey<DesktopShellState> shellKey =
      GlobalKey<DesktopShellState>();

  final int initialIndex;

  /// The owner keeps the index across a switch to the mobile layout and back.
  final ValueChanged<int>? onIndexChanged;

  DesktopShell({required this.initialIndex, this.onIndexChanged})
    : super(key: shellKey);

  static DesktopShellState? get current => shellKey.currentState;

  /// 0 when no shell is mounted; [DesktopWindowFrame] keeps its title bar clear of it.
  static final ValueNotifier<double> sidebarInset = ValueNotifier<double>(0);

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
    DesktopShell.sidebarInset.value = 0;
    super.dispose();
  }

  void select(int index) => _switchTo(index, record: true);

  /// [record] is false for Back/Forward, so they don't rewrite the history they walk.
  void _switchTo(int index, {required bool record}) {
    _suppressHistory = true;
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _suppressHistory = false;
    _routeForward.clear();
    if (_index.value == index) return;
    _logger.info('Desktop destination switched to: $index');
    if (record) {
      _tabBack.add(_index.value);
      _tabForward.clear();
    }
    setState(() => _index.value = index);
    if (index < navItems.length) widget.onIndexChanged?.call(index);
    if (index == NavTabs.browse && SettingsManager().autoFocusBrowseSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DesktopBrowseScreen.stateKey.currentState?.focusSearch();
      });
    }
  }

  void openSettings() => select(settingsIndex);

  @visibleForTesting
  set debugSidebarCollapsed(bool? value) =>
      setState(() => _collapsedOverride = value);

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

  final List<int> _tabBack = [];
  final List<int> _tabForward = [];

  /// Ready-to-push copies of routes popped by Back, newest last.
  final List<Route<dynamic>> _routeForward = [];

  bool _suppressHistory = false;
  bool _replaying = false;

  late final NavigatorObserver _historyObserver = _HistoryObserver(this);

  bool goBack() => _goBackImpl(this);

  bool goForward() => _goForwardImpl(this);

  bool popContent() => _popContentImpl(this);

  @override
  Widget build(BuildContext context) {
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
          // The sidebar animates over content laid out once; in a Row it re-laid out grids ~20x a toggle.
          body: DerivedLayoutBuilder<bool>(
            derive: (constraints) =>
                constraints.maxWidth < DesktopTokens.sidebarAutoCollapseWidth,
            builder: (context, narrow) {
              final collapsed = _collapsedOverride ?? narrow;
              final targetInset = collapsed
                  ? DesktopTokens.sidebarCollapsedWidth
                  : DesktopTokens.sidebarWidth;
              if (DesktopShell.sidebarInset.value != targetInset) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (DesktopShell.sidebarInset.value != targetInset) {
                    DesktopShell.sidebarInset.value = targetInset;
                  }
                });
              }
              return Stack(
                children: [
                  Positioned.fill(
                    left: collapsed
                        ? DesktopTokens.sidebarCollapsedWidth
                        : DesktopTokens.sidebarWidth,
                    child: Column(
                      children: [
                        BackendHealthBanner(
                          health: getIt<BackendHealthService>(),
                        ),
                        Expanded(child: _content),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: RepaintBoundary(
                      child: DesktopSidebar(
                        auth: getIt<ProfileAuthService>(),
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
              );
            },
          ),
        ),
      ),
    );
  }

  /// Built once: the navigator and its pages never rebuild for changes to the shell around them.
  late final Widget _content = _buildContent();

  Widget _buildContent() {
    return Stack(
      children: [
        Navigator(
          key: _contentNavigatorKey,
          observers: [_historyObserver],
          onGenerateInitialRoutes: (_, __) => [
            PageRouteBuilder<void>(
              opaque: true,
              pageBuilder: (_, __, ___) => ValueListenableBuilder<int>(
                valueListenable: _index,
                builder: (_, index, __) =>
                    ActivePageStack(index: index, children: _pages),
              ),
              transitionsBuilder: (_, __, ___, child) => child,
            ),
          ],
        ),
        SyncProgressOverlay(libraryService: getIt<LibraryService>()),
      ],
    );
  }
}
