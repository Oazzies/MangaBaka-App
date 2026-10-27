import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A pill-shaped chip. When it is tappable it answers a pointer: on hover its
/// border takes the accent — nothing grows or tints, so a row of tags reads as
/// clickable without the row shifting.
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

    Widget chip = Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border != null ? Border.all(color: border, width: 1) : null,
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

    if (_interactive) {
      // Laid over the chip so a chip without a border can gain one on hover
      // without changing size. Same quick fade as a series row's hover.
      chip = Stack(
        children: [
          chip,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: hovered ? colors.accent : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!_interactive) return chip;

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
