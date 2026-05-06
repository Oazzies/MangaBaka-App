import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class ContentRatingChip extends StatelessWidget {
  final String rating;
  const ContentRatingChip({required this.rating, super.key});

  @override
  Widget build(BuildContext context) {
    if (rating.isEmpty) return const SizedBox.shrink();

    Color color;
    IconData icon;
    switch (rating.toLowerCase()) {
      case 'suggestive':
        color = AppConstants.warningColor;
        icon = Icons.whatshot_outlined;
        break;
      case 'erotica':
      case 'pornographic':
        color = AppConstants.errorColor;
        icon = Icons.whatshot_outlined;
        break;
      case 'safe':
        color = AppConstants.successColor;
        icon = Icons.verified_outlined;
        break;
      default:
        color = AppConstants.textMutedColor;
        icon = Icons.info_outline;
    }

    return MiniBadge(
      text: rating,
      icon: icon,
      color: color,
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}
