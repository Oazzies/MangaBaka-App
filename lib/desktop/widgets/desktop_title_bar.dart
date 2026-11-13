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
import 'package:mangabaka_app/core/logging/logging_service.dart';

part 'desktop_title_bar_controls_part.dart';

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

final _logger = LoggingService.logger;

class DesktopTitleBar extends StatefulWidget implements PreferredSizeWidget {
  static const double height = 54.0;

  /// Custom callbacks used primarily for testing or custom handling.
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;
  final bool showMaximize;

  const DesktopTitleBar({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
    this.showMaximize = true,
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
              child: const TitleDragArea(),
            ),
          ),
          // Custom styled window controls
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 12),
            child: DesktopWindowButtons(
              onMinimize: widget.onMinimize,
              onMaximize: widget.onMaximize,
              onClose: widget.onClose,
              showMaximize: widget.showMaximize,
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
  final bool showMaximize;

  const DesktopWindowButtons({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
    this.showMaximize = true,
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
    } on Exception catch (e) {
      // Window chrome only; the platform window keeps its own controls.
      _logger.fine('Window manager call failed: $e');
    }
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
    } on Exception catch (e) {
      // Window chrome only; the platform window keeps its own controls.
      _logger.fine('Window manager call failed: $e');
    }
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
    } on Exception catch (e) {
      // Window chrome only; the platform window keeps its own controls.
      _logger.fine('Window manager call failed: $e');
    }
  }

  Future<void> _handleClose() async {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    try {
      await windowManager.close();
    } on Exception catch (e) {
      // Window chrome only; the platform window keeps its own controls.
      _logger.fine('Window manager call failed: $e');
    }
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
        if (widget.showMaximize) ...[
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
        ],
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
