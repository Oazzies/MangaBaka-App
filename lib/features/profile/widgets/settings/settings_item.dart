import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A single settings row.
///
/// Layout follows the design system's list idiom: a bare muted glyph anchors
/// the left edge, the title is set in display caps, and the value/summary sits
/// beneath it in muted sans.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
      bottom: isLast ? Radius.circular(AppConstants.cardRadius) : Radius.zero,
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, color: context.colors.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
                size: 22,
              ),
        ],
      ),
    );

    // A row with a switch/other control in its trailing slot is not itself
    // tappable, so it must not get press feedback.
    if (onTap == null) return row;

    return MbTappable(
      onTap: onTap,
      pressedScale: 0.985,
      child: ClipRRect(borderRadius: radius, child: row),
    );
  }
}
