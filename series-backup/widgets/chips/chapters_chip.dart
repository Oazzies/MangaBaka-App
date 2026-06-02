import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';

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

    if (inLibrary) return const SizedBox.shrink();

    return MiniBadge(
      text: '$chapters Ch.',
      icon: Icons.format_list_bulleted,
    );
  }
}
