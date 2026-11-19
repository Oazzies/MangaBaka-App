import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class DesktopLayout {
  DesktopLayout._();

  /// Below this the sidebar, a filter panel and a useful results grid no longer fit side by side.
  static const double minWidth = 1000;

  @visibleForTesting
  static bool? debugOverride;

  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Without a [DesktopLayoutScope] above, this rebuilds the caller on every frame of a resize.
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

abstract final class DesktopTokens {
  static const double sidebarWidth = 236;
  static const double sidebarCollapsedWidth = 76;

  static const double sidebarAutoCollapseWidth = 1180;

  static const double panelWidth = 288;

  static const double pagePadding = 32;

  static const double sectionGap = 36;

  static const double readableWidth = 760;

  static const double maxPageWidth = 1640;

  static const double panelRadius = 16;

  /// 3 buttons at 38px + 2 gaps at 8px + 12px right padding.
  static const double windowControlsWidth = 142;

  static const double windowControlsClearance = 160;
}
