import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'dart:io';

class TrackpadNavigationListener extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBack;

  const TrackpadNavigationListener({
    super.key,
    required this.child,
    this.onBack,
  });

  @override
  State<TrackpadNavigationListener> createState() =>
      _TrackpadNavigationListenerState();
}

class _TrackpadNavigationListenerState
    extends State<TrackpadNavigationListener> {
  double _cumulativeDelta = 0;
  static const double _threshold = 250.0;
  DateTime? _lastNavigationTime;
  static const Duration _cooldown = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    // Only enable on macOS
    try {
      if (!Platform.isMacOS) return widget.child;
    } on UnsupportedError {
      // In web, Platform.isMacOS might throw or be false
      return widget.child;
    }

    return Listener(
      onPointerPanZoomUpdate: (event) {
        // macOS trackpad 2-finger horizontal swipe is reported as panDelta
        final dx = event.panDelta.dx;
        final dy = event.panDelta.dy;

        // Only accumulate if the movement is primarily horizontal
        if (dx.abs() > dy.abs()) {
          _cumulativeDelta += dx;

          // Swipe from left to right (dx > 0) is "Back"
          if (_cumulativeDelta > _threshold) {
            _cumulativeDelta = 0;

            // Prevent multiple rapid pops from a single gesture stream
            final now = DateTime.now();
            if (_lastNavigationTime != null &&
                now.difference(_lastNavigationTime!) < _cooldown) {
              return;
            }
            _lastNavigationTime = now;

            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              final navigator = AppConstants.navigatorKey.currentState;
              if (navigator != null && navigator.canPop()) {
                navigator.maybePop();
              }
            }
          } else if (_cumulativeDelta < -_threshold) {
            // Forward navigation could be here, but we focus on back
            _cumulativeDelta = 0;
          }
        } else if (dy.abs() > dx.abs() * 2) {
          // If the movement is clearly vertical, reset cumulative horizontal delta
          // to prevent accidental triggers from diagonal scrolling
          _cumulativeDelta = 0;
        }
      },
      onPointerPanZoomEnd: (event) {
        // Reset when the gesture ends
        _cumulativeDelta = 0;
      },
      child: widget.child,
    );
  }
}
