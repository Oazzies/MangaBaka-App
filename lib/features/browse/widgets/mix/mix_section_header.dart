import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MixSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  final String? trailing;

  final double trailingFontSize;

  const MixSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.trailingFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.colors.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: trailingFontSize,
              fontWeight: trailingFontSize > 12
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }
}
