import 'package:flutter/material.dart';

/// Motion tokens for the Ink & Amber system.
///
/// One vocabulary of durations and curves so every transition in the app feels
/// like it came from the same hand. Durations are deliberately short — this is
/// a browsing app, and motion that reads as "snappy" survives repetition where
/// motion that reads as "cinematic" starts to feel slow by the tenth time.
abstract final class AppMotion {
  /// Press feedback, hovers, colour swaps.
  static const Duration fast = Duration(milliseconds: 140);

  /// The default: entrances, expansions, most state changes.
  static const Duration base = Duration(milliseconds: 260);

  /// Page transitions and larger surfaces (sheets, dialogs).
  static const Duration slow = Duration(milliseconds: 360);

  /// Standard decelerate — anything entering the screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Anything leaving the screen.
  static const Curve exit = Curves.easeInCubic;

  /// Emphasised in-out for things that move and settle.
  static const Curve emphasized = Curves.easeInOutCubic;

  /// A slight overshoot, for elements that should feel physical (press
  /// release, the amber selection disc).
  static const Curve overshoot = Curves.easeOutBack;

  /// Per-item delay in a staggered list. Capped by [staggerCap] so a long
  /// list never leaves the last rows waiting.
  static const Duration stagger = Duration(milliseconds: 32);

  /// Highest stagger index that still receives a delay.
  static const int staggerCap = 8;

  static Duration staggerDelay(int index) =>
      stagger * index.clamp(0, staggerCap);
}

/// Fade-and-rise entrance, optionally staggered by [index].
///
/// Used for list rows, rails and card grids so content arrives rather than
/// simply appearing. Runs once on first build.
///
/// Only the content that arrives together animates: inside a scrollable, an
/// entrance plays only within [window] of the first one in that scrollable.
/// Rows built later because they scrolled into view (or paged in) show at once,
/// instead of fading in at the screen edge as the reader scrolls.
class MbEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  /// Distance in logical pixels the child rises through.
  final double offset;

  const MbEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppMotion.base,
    this.offset = 14,
  });

  @override
  State<MbEntrance> createState() => _MbEntranceState();
}

class _MbEntranceState extends State<MbEntrance>
    with SingleTickerProviderStateMixin {
  late final Duration _delay = AppMotion.staggerDelay(widget.index);

  // The stagger is expressed as a leading Interval on a single controller
  // rather than a delayed start. A pending Timer would outlive the widget on
  // dispose (and fails widget tests outright); an Interval is cancelled with
  // the controller for free.
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

  /// When the first entrance in each scrollable was built.
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
            offset: Offset(0, (1 - _curved.value) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps a tappable surface with a subtle scale-down while held.
///
/// The design system's buttons are flat blocks of colour, so they have no
/// depth cue of their own; this supplies the "it moved when I touched it"
/// feedback that flat surfaces otherwise lack.
class MbTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale at full press. Larger surfaces want a shallower dip.
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
