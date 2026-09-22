import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The accent icon + uppercase display title that heads each Mix section, with
/// an optional muted trailing note.
///
/// The four sections had four copies of this row; they drifted apart on
/// spacing and letter-spacing, which showed as uneven headings down the page.
class MixSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Muted text set after the title — a subtitle on the DNA header, the result
  /// count on the results header.
  final String? trailing;

  /// Trailing text is normally small print; the results count is set at title
  /// size instead.
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
