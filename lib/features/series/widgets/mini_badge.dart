import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MiniBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  /// Override the hover/splash color. Defaults to a neutral light gray that
  /// matches the default InkWell highlight used by the state-update button.
  final Color? hoverColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const MiniBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
    this.hoverColor,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = onTap != null;
    final bg = backgroundColor ?? context.colors.surface;
    // Neutral hover a shade toward the ink, matching the default InkWell
    // highlight on the state-update / progress buttons.
    final effectiveHoverColor =
        hoverColor ?? context.colors.text.withValues(alpha: 0.08);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? context.colors.textMuted),
            const SizedBox(width: 8),
          ],
          Text(
            text.toUpperCase(),
            style: AppTypography.sans(
              color: color ?? context.colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    final badge = isClickable
        ? Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              hoverColor: effectiveHoverColor,
              splashColor: effectiveHoverColor,
              highlightColor: effectiveHoverColor.withValues(
                alpha: effectiveHoverColor.a * 0.6,
              ),
              child: content,
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: content,
          );

    if (tooltip != null) {
      return WidgetUtils.tooltip(message: tooltip!, child: badge);
    }

    return badge;
  }
}
