import 'package:flutter/material.dart';

/// Durations are deliberately short: snappy motion survives repetition in a browsing app.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);

  static const Duration base = Duration(milliseconds: 260);

  static const Duration slow = Duration(milliseconds: 360);

  static const Curve enter = Curves.easeOutCubic;

  static const Curve exit = Curves.easeInCubic;

  static const Curve emphasized = Curves.easeInOutCubic;

  static const Curve overshoot = Curves.easeOutBack;

  static const Duration stagger = Duration(milliseconds: 32);

  static const int staggerCap = 8;

  static Duration staggerDelay(int index) =>
      stagger * index.clamp(0, staggerCap);
}

/// Inside a scrollable only entrances within [window] of the first animate; later rows show at once.
class MbEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  final double riseDistance;

  const MbEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.base,
    this.riseDistance = 14,
  });

  @override
  State<MbEntrance> createState() => _MbEntranceState();
}

class _MbEntranceState extends State<MbEntrance>
    with SingleTickerProviderStateMixin {
  late final Duration _delay = AppMotion.staggerDelay(widget.index);

  // Stagger is a leading Interval: a delayed start's Timer outlives dispose and fails widget tests.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + widget.duration,
  );

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMicroseconds /
          (_delay + widget.duration).inMicroseconds.clamp(1, 1 << 31),
      1.0,
      curve: AppMotion.enter,
    ),
  );

  static final Expando<DateTime> _windowStart = Expando('MbEntrance window');
  static const Duration _window = Duration(milliseconds: 700);

  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final position = Scrollable.maybeOf(context)?.position;
    var animate = true;
    if (position != null) {
      final now = DateTime.now();
      final start = _windowStart[position] ??= now;
      animate = now.difference(start) < _window;
    }
    if (animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curved.value) * widget.riseDistance),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class MbTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final double pressedScale;

  const MbTappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
  });

  @override
  State<MbTappable> createState() => _MbTappableState();
}

class _MbTappableState extends State<MbTappable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
