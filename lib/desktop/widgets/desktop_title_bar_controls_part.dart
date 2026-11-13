part of 'desktop_title_bar.dart';

/// A custom-styled circular window button matching MangaBaka's button design language:
/// - 38px height (same as sort by dropdown)
/// - Solid background colors (no semi-transparent)
/// - No border
/// - MbTappable tactile scale feedback
/// - Tooltip support
class _AppWindowButton extends StatefulWidget {
  final String tooltip;
  final Widget Function(Color color, Color bgColor) buildIcon;
  final VoidCallback onPressed;
  final bool isClose;
  final bool enabled;

  const _AppWindowButton({
    required this.tooltip,
    required this.buildIcon,
    required this.onPressed,
    this.isClose = false,
    this.enabled = true,
  });

  @override
  State<_AppWindowButton> createState() => _AppWindowButtonState();
}

class _AppWindowButtonState extends State<_AppWindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return SizedBox(
        width: 38,
        height: 38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          child: Center(
            child: widget.buildIcon(
              context.colors.textMuted.withValues(alpha: 0.3),
              context.colors.surfaceRaised,
            ),
          ),
        ),
      );
    }

    Color bgColor = context.colors.surfaceRaised;
    Color iconColor = context.colors.text;

    if (widget.isClose) {
      if (_hovered) {
        bgColor = FixedColors.windowsClose;
        iconColor = context.colors.on(FixedColors.windowsClose);
      }
    } else {
      if (_hovered) {
        bgColor = context.colors.border;
      }
    }

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: MbTappable(
        onTap: widget.onPressed,
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          child: Center(child: widget.buildIcon(iconColor, bgColor)),
        ),
      ),
    );

    if (SettingsManager().showTooltips) {
      button = Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return Semantics(label: widget.tooltip, button: true, child: button);
  }
}

/// A crisp floating-window icon representing "Restore from expanded to a floating window".
class FloatingWindowRestoreIcon extends StatelessWidget {
  final Color color;
  final Color fillColor;
  final double size;

  const FloatingWindowRestoreIcon({
    super.key,
    required this.color,
    required this.fillColor,
    this.size = 17,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FloatingWindowPainter(color: color, fillColor: fillColor),
    );
  }
}

class _FloatingWindowPainter extends CustomPainter {
  final Color color;
  final Color fillColor;

  const _FloatingWindowPainter({required this.color, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final backPath = Path()
      ..moveTo(w * 0.40, h * 0.16)
      ..lineTo(w * 0.80, h * 0.16)
      ..arcToPoint(
        Offset(w * 0.84, h * 0.20),
        radius: const Radius.circular(1.5),
      )
      ..lineTo(w * 0.84, h * 0.60);
    canvas.drawPath(backPath, strokePaint);

    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.36, w * 0.50, h * 0.50),
      const Radius.circular(1.8),
    );

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frontRect, fillPaint);
    canvas.drawRRect(frontRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _FloatingWindowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// The draggable strip of the title bar: press and move to drag the window,
/// double-click to maximize or restore.
class TitleDragArea extends StatefulWidget {
  const TitleDragArea({super.key});

  @override
  State<TitleDragArea> createState() => _TitleDragAreaState();
}

class _TitleDragAreaState extends State<TitleDragArea> {
  static const double _dragSlop = 4;
  static const Duration _doubleClick = Duration(milliseconds: 350);

  Offset? _down;
  bool _dragging = false;
  DateTime? _lastUp;

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _down = e.position;
        _dragging = false;
      },
      onPointerMove: (e) {
        final down = _down;
        if (down == null || _dragging) return;
        if ((e.position - down).distance > _dragSlop) {
          _dragging = true;
          windowManager.startDragging();
        }
      },
      onPointerUp: (e) {
        if (!_dragging) {
          final now = DateTime.now();
          final last = _lastUp;
          if (last != null && now.difference(last) < _doubleClick) {
            _lastUp = null;
            _toggleMaximize();
          } else {
            _lastUp = now;
          }
        }
        _down = null;
        _dragging = false;
      },
      child: const SizedBox(width: double.infinity, height: double.infinity),
    );
  }
}
