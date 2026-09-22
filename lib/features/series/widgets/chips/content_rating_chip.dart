import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
        color = context.colors.warning;
        icon = Icons.whatshot_outlined;
        break;
      case 'erotica':
      case 'pornographic':
        color = context.colors.error;
        icon = Icons.whatshot_outlined;
        break;
      case 'safe':
        color = context.colors.success;
        icon = Icons.verified_outlined;
        break;
      default:
        color = context.colors.textMuted;
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
