import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesSectionHeader extends StatelessWidget {
  final String title;
  final double bottomPadding;

  const SeriesSectionHeader({
    super.key,
    required this.title,
    this.bottomPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Signature design-system label: uppercase, letter-spaced monospace.
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.monoLabel(
          color: context.colors.textMuted,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
