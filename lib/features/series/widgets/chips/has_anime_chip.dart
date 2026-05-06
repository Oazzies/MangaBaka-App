import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';

class HasAnimeChip extends StatelessWidget {
  const HasAnimeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiniBadge(
      text: 'Anime',
      icon: Icons.ondemand_video_outlined,
    );
  }
}
