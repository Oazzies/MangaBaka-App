import 'package:flutter/material.dart';
import '../chip.dart';

class HasAnimeChip extends StatelessWidget {
  const HasAnimeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ondemand_video_outlined, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text('Anime'),
        ],
      ),
    );
  }
}