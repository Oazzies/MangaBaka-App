import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

class SeriesMetadataTonalRow extends StatelessWidget {
  final String? author;
  final String? chapters;
  final String? score;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onChaptersTap;
  final VoidCallback? onScoreTap;

  const SeriesMetadataTonalRow({
    super.key,
    this.author,
    this.chapters,
    this.score,
    this.onAuthorTap,
    this.onChaptersTap,
    this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.0, color: AppConstants.textMutedColor,
    );
    final valueStyle = TextStyle(
      fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textColor,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildCell('Author', author ?? '--', onAuthorTap, labelStyle, valueStyle, alignEnd: false),
          _divider(),
          _buildCell('Chapters', chapters ?? '--', onChaptersTap, labelStyle, valueStyle, alignEnd: false),
          _divider(),
          _buildCell('Global Metric', score ?? '--', onScoreTap, labelStyle, valueStyle, alignEnd: true, showStar: true),
        ],
      ),
    );
  }

  Widget _buildCell(String label, String value, VoidCallback? onTap,
      TextStyle labelStyle, TextStyle valueStyle,
      {required bool alignEnd, bool showStar = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(), style: labelStyle),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showStar)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.star_rounded, size: 14, color: AppConstants.accentColor),
                  ),
                Flexible(child: Text(value, style: valueStyle, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: AppConstants.tertiaryBackground);
  }
}
