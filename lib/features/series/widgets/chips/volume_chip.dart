import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';

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

    if (inLibrary) return const SizedBox.shrink();

    return MiniBadge(
      text: '$volume Vol.',
      icon: Icons.shelves,
    );
  }
}
