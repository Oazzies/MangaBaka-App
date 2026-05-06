import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class ChaptersChip extends StatelessWidget {
  final String chapters;
  final int? progress;
  final bool inLibrary;

  const ChaptersChip({
    required this.chapters,
    this.progress,
    this.inLibrary = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty || chapters == 'null') return const SizedBox.shrink();

    if (inLibrary) {
      final progressValue = progress ?? 0;
      return MiniBadge(
        text: '$progressValue / $chapters CHS',
        icon: Icons.format_list_bulleted,
        color: AppConstants.successColor,
        backgroundColor: AppConstants.successColor.withValues(alpha: 0.1),
      );
    }

    return MiniBadge(
      text: '$chapters CHS',
      icon: Icons.format_list_bulleted,
    );
  }
}
