import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

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
          color: AppConstants.textMutedColor,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
