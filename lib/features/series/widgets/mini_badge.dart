import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

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
    final bg = backgroundColor ?? AppConstants.secondaryBackground;
    // Neutral light-gray hover, matching the default InkWell highlight on
    // the state-update / progress buttons.
    final effectiveHoverColor = hoverColor ?? Colors.white.withValues(alpha: 0.08);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: color ?? AppConstants.textMutedColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color ?? AppConstants.textColor,
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
              highlightColor:
                  effectiveHoverColor.withValues(alpha: effectiveHoverColor.a * 0.6),
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
      return Tooltip(
        message: tooltip!,
        child: badge,
      );
    }

    return badge;
  }
}
