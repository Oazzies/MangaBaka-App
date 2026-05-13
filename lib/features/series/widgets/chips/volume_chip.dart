import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class VolumeChip extends StatelessWidget {
  final String volume;
  final int? progress;
  final bool inLibrary;
  final VoidCallback? onTap;

  const VolumeChip({
    required this.volume,
    this.progress,
    this.inLibrary = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (volume.isEmpty || volume == 'null') return const SizedBox.shrink();

    if (inLibrary) {
      final progressValue = progress ?? 0;
      return MiniBadge(
        text: '$progressValue / $volume Vol.',
        icon: Icons.shelves,
        color: AppConstants.successColor,
        backgroundColor: AppConstants.successColor.withValues(alpha: 0.1),
        onTap: onTap,
        tooltip: onTap != null ? LocalizationService().translate('update_progress') : null,
      );
    }

    return MiniBadge(
      text: '$volume Vol.',
      icon: Icons.shelves,
    );
  }
}
