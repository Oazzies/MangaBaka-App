import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/shared/widgets/window_repaint_guard.dart';
import 'package:window_manager/window_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A sleek, custom Windows title overlay that integrates directly into the app
/// header without pushing the app content down.
///
/// Features:
/// - Transparent background: the app content and sidebar hit the very top of
///   the window (`y = 0`).
/// - Draggable area across the top header (`DragToMoveArea`), so users can drag
///   to reposition and double-click to expand/restore.
/// - Custom-styled window control buttons (minimize, expand/restore, close)
///   styled to match MangaBaka's design system: solid backgrounds, no borders,
///   matching the 38px height of dropdown controls, with tooltip support.
class DesktopTitleBar extends StatefulWidget implements PreferredSizeWidget {
  static const double height = 54.0;

  /// Custom callbacks used primarily for testing or custom handling.
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;

  const DesktopTitleBar({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
  });

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && DesktopLayout.isDesktopPlatform) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && DesktopLayout.isDesktopPlatform) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesktopTitleBar.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draggable area across the full height of the title strip, so the
          // window can be grabbed anywhere beside the window controls rather
          // than only in the few pixels at the very top. DragToMoveArea is
          // hit-test transparent, so content beneath it still gets its taps.
          Expanded(
            child: SizedBox(
              height: DesktopTitleBar.height,
              child: DragToMoveArea(
                child: const SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          // Custom styled window controls
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: DesktopWindowButtons(
              onMinimize: widget.onMinimize,
              onMaximize: widget.onMaximize,
              onClose: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trio of custom-styled window control buttons: Minimize, Expand/Restore, and Close.
class DesktopWindowButtons extends StatefulWidget {
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;

  const DesktopWindowButtons({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
  });

  @override
  State<DesktopWindowButtons> createState() => _DesktopWindowButtonsState();
}

class _DesktopWindowButtonsState extends State<DesktopWindowButtons>
    with WindowListener {
  bool _isExpanded = false;
  bool _isMaximizable = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && DesktopLayout.isDesktopPlatform) {
      windowManager.addListener(this);
      _updateWindowState();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && DesktopLayout.isDesktopPlatform) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _updateWindowState() async {
    try {
      final isMax = await windowManager.isMaximized();
      final isFull = await windowManager.isFullScreen();
      final isMaximizable = await windowManager.isMaximizable();
      if (mounted) {
        setState(() {
          _isExpanded = isMax || isFull;
          _isMaximizable = isMaximizable;
        });
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isExpanded = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isExpanded = false);
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isExpanded = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    _updateWindowState();
  }

  @override
  void onWindowRestore() {
    _updateWindowState();
  }

  Future<void> _handleMinimize() async {
    if (widget.onMinimize != null) {
      widget.onMinimize!();
      return;
    }
    try {
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      } else {
        await windowManager.minimize();
      }
    } catch (_) {}
  }

  Future<void> _handleMaximize() async {
    if (!_isMaximizable) return;
    if (widget.onMaximize != null) {
      widget.onMaximize!();
      return;
    }
    try {
      final isFull = await windowManager.isFullScreen();
      if (isFull) {
        await WindowRepaintGuard.toggleFullscreen();
        return;
      }
      final isMax = await windowManager.isMaximized();
      if (isMax) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  Future<void> _handleClose() async {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    try {
      await windowManager.close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppWindowButton(
          tooltip: 'Minimize',
          buildIcon: (color, _) =>
              Icon(Icons.remove_rounded, size: 18, color: color),
          onPressed: _handleMinimize,
        ),
        const SizedBox(width: 8),
        _AppWindowButton(
          tooltip: _isExpanded ? 'Restore' : 'Expand',
          buildIcon: (color, bgColor) => _isExpanded
              ? FloatingWindowRestoreIcon(
                  color: color,
                  fillColor: bgColor,
                  size: 17,
                )
              : Icon(Icons.crop_square_rounded, size: 18, color: color),
          enabled: _isMaximizable,
          onPressed: _handleMaximize,
        ),
        const SizedBox(width: 8),
        _AppWindowButton(
          tooltip: 'Close',
          buildIcon: (color, _) =>
              Icon(Icons.close_rounded, size: 18, color: color),
          isClose: true,
          onPressed: _handleClose,
        ),
      ],
    );
  }
}

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

    // Back window outline (top-right)
    final backPath = Path()
      ..moveTo(w * 0.40, h * 0.16)
      ..lineTo(w * 0.80, h * 0.16)
      ..arcToPoint(
        Offset(w * 0.84, h * 0.20),
        radius: const Radius.circular(1.5),
      )
      ..lineTo(w * 0.84, h * 0.60);
    canvas.drawPath(backPath, strokePaint);

    // Front floating window (bottom-left)
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.36, w * 0.50, h * 0.50),
      const Radius.circular(1.8),
    );

    // Fill front window with solid background color so back lines don't bleed through
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
