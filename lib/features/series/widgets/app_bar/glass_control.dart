import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class GlassControl extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  final String? label;

  final double size;

  final double iconSize;

  const GlassControl({
    super.key,
    required this.onTap,
    required this.icon,
    this.label,
    this.size = 40,
    this.iconSize = 19,
  });

  @override
  State<GlassControl> createState() => _GlassControlState();
}

class _GlassControlState extends State<GlassControl> {
  static final BorderRadius _radius = BorderRadius.circular(999);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = widget.label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          height: widget.size,
          width: label == null ? widget.size : null,
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
          decoration: BoxDecoration(
            color: _hovered ? colors.border : colors.surfaceRaised,
            borderRadius: _radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: widget.iconSize, color: colors.text),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
