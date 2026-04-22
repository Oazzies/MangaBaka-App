import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';
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
    if (chapters.isEmpty || chapters == 'null') return SizedBox.shrink();

    if (inLibrary) {
      final progressValue = progress ?? 0;
      return ChipBase(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_list_bulleted, size: 18, color: AppConstants.textColor),
            const SizedBox(width: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$progressValue',
                    style: TextStyle(
                      color: Color(0xFF16d492),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' of $chapters Ch.',
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_bulleted, size: 18, color: AppConstants.textColor),
          const SizedBox(width: 4),
          Text('$chapters Ch.'),
        ],
      ),
    );
  }
}
