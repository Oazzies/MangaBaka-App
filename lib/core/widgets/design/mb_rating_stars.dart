import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Single amber star followed by the numeric score, matching the reference's
/// compact "★ 5.0" treatment rather than a five-star row.
class MbRatingStars extends StatelessWidget {
  /// Score on the source's own scale; [outOf] is used only to decide how many
  /// decimals to show.
  final double? rating;
  final double outOf;
  final double fontSize;

  const MbRatingStars({
    super.key,
    required this.rating,
    this.outOf = 10,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final r = rating;
    if (r == null || r <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: fontSize + 4,
          color: context.colors.star,
        ),
        const SizedBox(width: 3),
        Text(
          r.toStringAsFixed(outOf > 10 ? 0 : 1),
          style: AppTypography.sans(
            color: context.colors.text,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
