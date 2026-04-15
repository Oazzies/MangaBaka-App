import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

class ChaptersChip extends StatelessWidget {
  final String chapters;
  const ChaptersChip({required this.chapters, super.key});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty || chapters == 'null') return SizedBox.shrink();
    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_bulleted, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text('$chapters Ch.'),
        ],
      ),
    );
  }
}