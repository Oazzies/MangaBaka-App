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
    final guard = _mounted;
    if (guard != null) {
      guard._forceFrames();
    } else {
      SchedulerBinding.instance.scheduleForcedFrame();
    }
  }

  static _WindowRepaintGuardState? _mounted;

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

  Timer? _debounceTimer;
  final List<Timer> _settleTimers = [];

  @override
  void initState() {
    super.initState();
    WindowRepaintGuard._mounted = this;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (identical(WindowRepaintGuard._mounted, this)) {
      WindowRepaintGuard._mounted = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _cancelSettleTimers();
    super.dispose();
  }

  void _forceFrames() {
    SchedulerBinding.instance.scheduleForcedFrame();
    _cancelSettleTimers();
    for (final delay in WindowRepaintGuard._settleDelays) {
      _settleTimers.add(
        Timer(delay, SchedulerBinding.instance.scheduleForcedFrame),
      );
    }
  }

  void _cancelSettleTimers() {
    for (final timer in _settleTimers) {
      timer.cancel();
    }
    _settleTimers.clear();
  }

  @override
  void didChangeMetrics() {
    if (!WindowRepaintGuard._isDesktop) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _forceFrames);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
