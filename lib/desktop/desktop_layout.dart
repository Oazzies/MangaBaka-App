import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Decides when the desktop presentation layer is used instead of the mobile
/// one.
///
/// The app is one codebase with two presentation layers over the same
/// services, controllers and models: `lib/features/**` holds the shared logic
/// and the phone/tablet screens, `lib/desktop/**` holds screens laid out for a
/// mouse, a keyboard and a wide window. This is the single switch between
/// them.
///
/// Desktop is a platform *and* a width: a desktop window dragged narrow is
/// phone-shaped, and there the mobile layouts genuinely fit better than a
/// sidebar with a filter panel squeezed beside it.
class DesktopLayout {
  DesktopLayout._();

  /// Narrowest window the desktop layout is used at. Below this the sidebar,
  /// a filter panel and a useful results grid no longer fit side by side.
  static const double minWidth = 1000;

  /// Forces the decision in tests, which run on whatever host they are on.
  @visibleForTesting
  static bool? debugOverride;

  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Whether [context] is in the desktop presentation.
  ///
  /// Under a [DesktopLayoutScope] (the app root has one) the caller only
  /// rebuilds when the answer flips. Without one it falls back to reading the
  /// window width — which rebuilds the caller on every frame of a resize, so
  /// the scope matters: list rows ask this.
  static bool isActive(BuildContext context) {
    final override = debugOverride;
    if (override != null) return override;
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DesktopLayoutScope>();
    if (scope != null) return scope.active;
    return _activeAt(MediaQuery.sizeOf(context).width);
  }

  static bool _activeAt(double width) => isDesktopPlatform && width >= minWidth;
}

/// Publishes [DesktopLayout.isActive] below it, notifying dependents only when
/// the answer changes rather than on every change of window size.
class DesktopLayoutScope extends StatelessWidget {
  final Widget child;

  const DesktopLayoutScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => _DesktopLayoutScope(
    active: DesktopLayout._activeAt(MediaQuery.sizeOf(context).width),
    child: child,
  );
}

class _DesktopLayoutScope extends InheritedWidget {
  final bool active;

  const _DesktopLayoutScope({required this.active, required super.child});

  @override
  bool updateShouldNotify(_DesktopLayoutScope oldWidget) =>
      active != oldWidget.active;
}

/// Spacing and sizing shared by every desktop screen, so the pages line up
/// with each other and with the shell around them.
abstract final class DesktopTokens {
  /// Sidebar width when expanded, and when collapsed to icons.
  static const double sidebarWidth = 236;
  static const double sidebarCollapsedWidth = 76;

  /// Below this window width the sidebar starts collapsed.
  static const double sidebarAutoCollapseWidth = 1180;

  /// The always-visible filter/secondary panel on Library and Browse.
  static const double panelWidth = 288;

  /// Page gutter around the main content column.
  static const double pagePadding = 32;

  /// Gap between major blocks on a page.
  static const double sectionGap = 36;

  /// Widest a reading column (settings, text-heavy pages) grows.
  static const double readableWidth = 760;

  /// Widest a dashboard-style page grows before it centres.
  static const double maxPageWidth = 1640;

  /// Corner radius of desktop panels and cards — tighter than the phone's,
  /// which reads better at desktop density.
  static const double panelRadius = 16;

  /// Total width occupied by the custom window controls on the top right
  /// (3 buttons at 38px + 2 gaps at 8px + 12px right padding = 142px).
  static const double windowControlsWidth = 142;

  /// Safe right clearance for page headers and top controls so they never
  /// clip or collide with the window controls.
  static const double windowControlsClearance = 160;
}
