import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';

class MiddleClickAutoScroll extends StatefulWidget {
  final Widget child;

  const MiddleClickAutoScroll({super.key, required this.child});

  @override
  State<MiddleClickAutoScroll> createState() => _MiddleClickAutoScrollState();
}

class _MiddleClickAutoScrollState extends State<MiddleClickAutoScroll>
    with SingleTickerProviderStateMixin {
  static const double _deadZone = 14;

  static const double _speedAt100 = 650;

  static const double _follow = 12;

  Ticker? _ticker;

  int? _pointer;
  Offset _anchor = Offset.zero;
  Offset _current = Offset.zero;
  Offset _speed = Offset.zero; // smoothed px/s
  ScrollPosition? _vertical;
  ScrollPosition? _horizontal;
  Duration _last = Duration.zero;

  bool get _active => _pointer != null;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (_active) {
      _stop();
      return;
    }
    if (event.kind != PointerDeviceKind.mouse ||
        event.buttons & kMiddleMouseButton == 0) {
      return;
    }

    final (vertical, horizontal) = _scrollablesAt(event);
    if (vertical == null && horizontal == null) return;

    setState(() {
      _pointer = event.pointer;
      _anchor = event.position;
      _current = event.position;
      _speed = Offset.zero;
      _vertical = vertical;
      _horizontal = horizontal;
    });
    _last = Duration.zero;
    (_ticker ??= createTicker(_tick)).start();
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    setState(() => _current = event.position);
  }

  void _up(PointerEvent event) {
    if (event.pointer == _pointer) _stop();
  }

  void _stop() {
    _ticker?.stop();
    setState(() {
      _pointer = null;
      _vertical = null;
      _horizontal = null;
    });
  }

  (ScrollPosition?, ScrollPosition?) _scrollablesAt(PointerDownEvent event) {
    final hit = HitTestResult();
    WidgetsBinding.instance.hitTestInView(hit, event.position, event.viewId);
    final order = <RenderObject, int>{};
    for (final entry in hit.path) {
      final target = entry.target;
      if (target is RenderObject) order.putIfAbsent(target, () => order.length);
    }

    ScrollPosition? vertical;
    ScrollPosition? horizontal;
    var verticalRank = 1 << 30;
    var horizontalRank = 1 << 30;

    void visit(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        final rank = order[element.renderObject];
        final position = state.position;
        if (rank != null &&
            !axisDirectionIsReversed(state.axisDirection) &&
            position.hasContentDimensions &&
            position.maxScrollExtent > position.minScrollExtent) {
          if (position.axis == Axis.vertical && rank < verticalRank) {
            vertical = position;
            verticalRank = rank;
          } else if (position.axis == Axis.horizontal &&
              rank < horizontalRank) {
            horizontal = position;
            horizontalRank = rank;
          }
        }
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return (vertical, horizontal);
  }

  double _targetSpeed(double distance) {
    final magnitude = distance.abs() - _deadZone;
    if (magnitude <= 0) return 0;
    final scaled = (math.pow(magnitude / 100, 1.3) * _speedAt100).toDouble();
    return distance.isNegative ? -scaled : scaled;
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;

    final offset = _current - _anchor;
    final target = Offset(
      _horizontal == null ? 0 : _targetSpeed(offset.dx),
      _vertical == null ? 0 : _targetSpeed(offset.dy),
    );
    // Exponential approach: frame-rate independent easing toward the target.
    _speed += (target - _speed) * (1 - math.exp(-dt * _follow));

    _drive(_vertical, _speed.dy * dt);
    _drive(_horizontal, _speed.dx * dt);
  }

  void _drive(ScrollPosition? position, double delta) {
    if (position == null || delta == 0 || !position.hasPixels) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  MouseCursor get _cursor {
    final d = _current - _anchor;
    final right = _horizontal != null && d.dx > _deadZone;
    final left = _horizontal != null && d.dx < -_deadZone;
    final down = _vertical != null && d.dy > _deadZone;
    final up = _vertical != null && d.dy < -_deadZone;
    if (up && left) return SystemMouseCursors.resizeUpLeft;
    if (up && right) return SystemMouseCursors.resizeUpRight;
    if (down && left) return SystemMouseCursors.resizeDownLeft;
    if (down && right) return SystemMouseCursors.resizeDownRight;
    if (up) return SystemMouseCursors.resizeUp;
    if (down) return SystemMouseCursors.resizeDown;
    if (left) return SystemMouseCursors.resizeLeft;
    if (right) return SystemMouseCursors.resizeRight;
    return SystemMouseCursors.allScroll;
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopLayout.isDesktopPlatform) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          // On top so the cursor is ours; pointer events pass through to what's below.
          if (_active)
            Positioned.fill(
              child: MouseRegion(
                cursor: _cursor,
                opaque: false,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}
