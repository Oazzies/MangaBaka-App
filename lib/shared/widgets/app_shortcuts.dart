import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:mangabaka_app/shared/widgets/middle_click_autoscroll.dart';
import 'package:mangabaka_app/shared/widgets/mouse_navigation_listener.dart';
import 'package:mangabaka_app/shared/widgets/trackpad_navigation_listener.dart';
import 'package:mangabaka_app/shared/widgets/window_repaint_guard.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';

class BackIntent extends Intent {
  const BackIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class TabIntent extends Intent {
  final int index;
  const TabIntent(this.index);
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class FullscreenIntent extends Intent {
  const FullscreenIntent();
}

class AppShortcuts extends StatelessWidget {
  final Widget child;

  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const BackIntent(),
        const SingleActivator(LogicalKeyboardKey.f11): const FullscreenIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
            const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma):
            const SettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            const RefreshIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR):
            const RefreshIntent(),

        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1):
            const TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1):
            const TabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2):
            const TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2):
            const TabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3):
            const TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3):
            const TabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4):
            const TabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4):
            const TabIntent(3),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5):
            const TabIntent(4),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit5):
            const TabIntent(4),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (intent) {
              if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                windowManager.isFullScreen().then((isFull) {
                  if (isFull) {
                    WindowRepaintGuard.toggleFullscreen();
                    return;
                  }
                  final navigator = AppConstants.navigatorKey.currentState;
                  if (navigator != null && navigator.canPop()) {
                    navigator.maybePop();
                    return;
                  }
                  DesktopShell.current?.popContent();
                });
                return null;
              }
              // Root navigator first (dialogs, full-window routes), then the desktop content area.
              final navigator = AppConstants.navigatorKey.currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.maybePop();
                return null;
              }
              DesktopShell.current?.popContent();
              return null;
            },
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (intent) {
              final context = AppConstants.navigatorKey.currentContext;
              if (context != null) SettingsScreen.show(context);
              return null;
            },
          ),
          TabIntent: CallbackAction<TabIntent>(
            onInvoke: (intent) {
              MainScreen.setTabIndex(intent.index);
              return null;
            },
          ),
          FullscreenIntent: CallbackAction<FullscreenIntent>(
            onInvoke: (intent) {
              WindowRepaintGuard.toggleFullscreen();
              return null;
            },
          ),
        },
        child: WindowRepaintGuard(
          child: MouseNavigationListener(
            child: MiddleClickAutoScroll(
              child: TrackpadNavigationListener(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
