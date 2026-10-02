import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';

/// Maps a mouse's side buttons to navigation: button 4 goes Back, button 5
/// goes Forward. Desktop only.
///
/// Back first closes whatever sits on the root navigator (dialogs, full-window
/// pages), then the open page in the desktop shell, then returns to the
/// previous destination. Forward reopens the page Back closed, or moves on to
/// the destination Back left.
class MouseNavigationListener extends StatelessWidget {
  final Widget child;

  const MouseNavigationListener({super.key, required this.child});

  void _back() {
    final root = AppConstants.navigatorKey.currentState;
    if (root != null && root.canPop()) {
      root.maybePop();
      return;
    }
    DesktopShell.current?.goBack();
  }

  void _forward() => DesktopShell.current?.goForward();

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isDesktopPlatform) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind != PointerDeviceKind.mouse) return;
        if (event.buttons & kBackMouseButton != 0) {
          _back();
        } else if (event.buttons & kForwardMouseButton != 0) {
          _forward();
        }
      },
      child: child,
    );
  }
}
