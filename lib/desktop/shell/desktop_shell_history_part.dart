part of 'desktop_shell.dart';

Route<dynamic>? _replicaRoute(Route<dynamic> route) {
  if (route is PageRouteBuilder) {
    return PageRouteBuilder<dynamic>(
      settings: route.settings,
      opaque: route.opaque,
      pageBuilder: route.pageBuilder,
      transitionsBuilder: route.transitionsBuilder,
      transitionDuration: route.transitionDuration,
      reverseTransitionDuration: route.reverseTransitionDuration,
    );
  }
  if (route is MaterialPageRoute) {
    return MaterialPageRoute<dynamic>(
      settings: route.settings,
      builder: route.builder,
    );
  }
  return null;
}

/// Feeds the shell's Back/Forward history: remembers what was popped so
/// Forward can reopen it, and forgets that as soon as something new opens.
class _HistoryObserver extends NavigatorObserver {
  final DesktopShellState _shell;

  _HistoryObserver(this._shell);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_shell._suppressHistory || previousRoute == null) return;
    final copy = _replicaRoute(route);
    if (copy != null) _shell._routeForward.add(copy);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_shell._replaying || previousRoute == null || route is! PageRoute) {
      return;
    }
    _shell._routeForward.clear();
  }
}

bool _goBackImpl(DesktopShellState self) {
  final navigator = self._contentNavigatorKey.currentState;
  if (navigator != null && navigator.canPop()) {
    navigator.maybePop();
    return true;
  }
  if (self._tabBack.isEmpty) return false;
  self._tabForward.add(self._index.value);
  self._switchTo(self._tabBack.removeLast(), record: false);
  return true;
}

bool _goForwardImpl(DesktopShellState self) {
  final navigator = self._contentNavigatorKey.currentState;
  if (navigator != null && self._routeForward.isNotEmpty) {
    self._replaying = true;
    navigator.push(self._routeForward.removeLast());
    self._replaying = false;
    return true;
  }
  if (self._tabForward.isEmpty) return false;
  self._tabBack.add(self._index.value);
  self._switchTo(self._tabForward.removeLast(), record: false);
  return true;
}

bool _popContentImpl(DesktopShellState self) {
  final navigator = self._contentNavigatorKey.currentState;
  if (navigator == null || !navigator.canPop()) return false;
  navigator.maybePop();
  return true;
}
