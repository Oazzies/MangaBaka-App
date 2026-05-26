import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero_cover.dart';
import 'package:mangabaka_app/features/series/widgets/hoverable_title.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeriesDetailBottomContent extends StatelessWidget {
  final Series series;
  final String title;
  final bool isWide;
  final bool showCover;
  final bool isLoaded;
  final bool isLandscape;
  final double horizontalPadding;
  final Function(String) onCopy;

  const SeriesDetailBottomContent({
    super.key,
    required this.series,
    required this.title,
    required this.isWide,
    required this.showCover,
    required this.isLoaded,
    required this.isLandscape,
    required this.horizontalPadding,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showCover) ...[
            SeriesHeroCover(
                  series: series,
                  height: isWide
                      ? (isLandscape ? 180 : 220)
                      : (isLandscape ? 140 : 180),
                  width: isWide
                      ? (isLandscape ? 120 : 150)
                      : (isLandscape ? 100 : 125),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _buildMainInfo()
                .animate(target: isLoaded ? 1 : 0)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo() {
    final otherTitles = <String>[];
    if (series.title.isNotEmpty && series.title != title) {
      otherTitles.add(series.title);
    }
    if (series.nativeTitle.isNotEmpty &&
        series.nativeTitle != title &&
        !otherTitles.contains(series.nativeTitle)) {
      otherTitles.add(series.nativeTitle);
    }
    if (series.romanizedTitle.isNotEmpty &&
        series.romanizedTitle != title &&
        !otherTitles.contains(series.romanizedTitle)) {
      otherTitles.add(series.romanizedTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HoverableTitle(
          text: title,
          fontSize: isWide ? 32 : 22,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          maxLines: 3,
          shadows: [
            Shadow(
              color: AppConstants.primaryBackground.withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
          onTap: () => onCopy(title),
        ),
        if (otherTitles.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...otherTitles.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: HoverableTitle(
                text: t,
                fontSize: isWide ? 15 : 13,
                color: AppConstants.textMutedColor,
                fontStyle: FontStyle.italic,
                maxLines: 1,
                onTap: () => onCopy(t),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
