import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SettingsItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;

  final Widget? leadingIcon;

  const SettingsItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.leadingIcon,
  }) : assert(icon != null || leadingIcon != null);

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
            child: Center(
              child:
                  leadingIcon ??
                  Icon(icon, color: context.colors.textMuted, size: 20),
            ),
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

    if (onTap == null) return row;

    return MbTappable(
      onTap: onTap,
      pressedScale: 0.985,
      child: ClipRRect(borderRadius: radius, child: row),
    );
  }
}
