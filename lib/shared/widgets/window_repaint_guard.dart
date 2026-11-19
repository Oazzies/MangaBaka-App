import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';

/// Toggling fullscreen can leave a frame from an intermediate native size on screen until a repaint.
class WindowRepaintGuard extends StatefulWidget {
  final Widget child;

  const WindowRepaintGuard({super.key, required this.child});

  static Future<void> toggleFullscreen() async {
    if (!_isDesktop) return;
    final isFull = await windowManager.isFullScreen();
    if (isFull) {
      if (Platform.isWindows) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
      }
      await windowManager.setFullScreen(false);
      if (Platform.isWindows) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
      }
    } else {
      await windowManager.setFullScreen(true);
    }
    // Redundant with the metrics observer, but removes any dependence on the engine reporting it.
    forceFrames();
  }

  static void forceFrames() {
    SchedulerBinding.instance.scheduleForcedFrame();
    for (final delay in _settleDelays) {
      Timer(delay, SchedulerBinding.instance.scheduleForcedFrame);
    }
  }

  /// Long enough to land after the last native resize step of a fullscreen transition.
  static const List<Duration> _settleDelays = [
    Duration(milliseconds: 120),
    Duration(milliseconds: 400),
  ];

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  State<WindowRepaintGuard> createState() => _WindowRepaintGuardState();
}

class _WindowRepaintGuardState extends State<WindowRepaintGuard>
    with WidgetsBindingObserver {
  /// Metrics change on every step of a drag-resize; only the last matters.
  static const Duration _debounce = Duration(milliseconds: 80);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!WindowRepaintGuard._isDesktop) return;
    _timer?.cancel();
    _timer = Timer(_debounce, WindowRepaintGuard.forceFrames);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
