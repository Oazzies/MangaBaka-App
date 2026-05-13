import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class ChaptersChip extends StatelessWidget {
  final String chapters;
  final int? progress;
  final bool inLibrary;
  final VoidCallback? onTap;

  const ChaptersChip({
    required this.chapters,
    this.progress,
    this.inLibrary = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty || chapters == 'null') return const SizedBox.shrink();

    if (inLibrary) {
      final progressValue = progress ?? 0;
      return MiniBadge(
        text: '$progressValue / $chapters Ch.',
        icon: Icons.format_list_bulleted,
        color: AppConstants.successColor,
        backgroundColor: AppConstants.successColor.withValues(alpha: 0.1),
        onTap: onTap,
        tooltip: onTap != null ? LocalizationService().translate('update_progress') : null,
      );
    }

    return MiniBadge(
      text: '$chapters Ch.',
      icon: Icons.format_list_bulleted,
    );
  }
}
