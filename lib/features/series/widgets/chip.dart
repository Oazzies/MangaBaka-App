import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A pill-shaped chip. When it is tappable it answers a pointer: on hover it
/// warms toward the accent, its border takes the accent, and it lifts a hair —
/// so a row of tags reads as clickable before anything is pressed.
class ChipBase extends StatefulWidget {
  final Widget label;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Right-click on desktop — the pointer counterpart of [onLongPress].
  final VoidCallback? onSecondaryTap;

  /// Shown on hover, e.g. what a right-click does.
  final String? tooltip;

  const ChipBase({
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.padding,
    this.labelStyle,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.tooltip,
    super.key,
  });

  @override
  State<ChipBase> createState() => _ChipBaseState();
}

class _ChipBaseState extends State<ChipBase> {
  bool _hovered = false;

  bool get _interactive =>
      widget.onTap != null ||
      widget.onLongPress != null ||
      widget.onSecondaryTap != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = widget.backgroundColor ?? colors.surface;
    final border = widget.borderColor;
    final hovered = _interactive && _hovered;

    final bg = hovered ? Color.lerp(base, colors.accent, 0.16)! : base;
    final borderColor = hovered
        ? colors.accent.withValues(alpha: 0.85)
        : border;

    Widget chip = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: DefaultTextStyle(
        style: widget.labelStyle ??
            AppTypography.sans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.text,
              height: 1.2,
            ),
        child: widget.label,
      ),
    );

    if (!_interactive) return chip;

    chip = AnimatedScale(
      scale: hovered ? 1.04 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      child: chip,
    );

    Widget interactive = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: chip,
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      interactive = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 600),
        child: interactive,
      );
    }
    return interactive;
  }
}
