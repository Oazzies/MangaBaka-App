import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class RatingChip extends StatelessWidget {
  final List<dynamic> sources;
  final LibraryEntry? entry;
  final VoidCallback? onTap;

  const RatingChip({
    required this.sources,
    this.entry,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Treat 0 as unrated
    final userRatingValue = entry?.rating ?? 0;
    final int? userRating = userRatingValue > 0 ? userRatingValue : null;
    
    // The badge is only present when the user has personally rated the series
    if (userRating == null) return const SizedBox.shrink();

    return MiniBadge(
      text: '$userRating / 100',
      icon: Icons.star,
      color: AppConstants.warningColor,
      backgroundColor: AppConstants.warningColor.withValues(alpha: 0.1),
      hoverColor: AppConstants.warningColor.withValues(alpha: 0.15),
      onTap: onTap,
      tooltip: onTap != null ? LocalizationService().translate('show_rating') : null,
    );
  }
}
