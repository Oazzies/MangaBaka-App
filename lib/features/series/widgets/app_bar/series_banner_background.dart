import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero_cover.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesBannerBackground extends StatelessWidget {
  final Series series;
  final String title;

  final bool isWide;
  final bool showCover;
  final double horizontalPadding;
  final double coverHeight;
  final double coverWidth;
  final String? heroTagPrefix;

  /// Holds back the [ImageFiltered] blur, the most expensive thing on this page, until the slide is over.
  final bool transitionComplete;

  /// Must match the page body's max content width.
  static const double _maxContentWidth = 1400;

  const SeriesBannerBackground({
    super.key,
    required this.series,
    required this.title,
    required this.isWide,
    required this.showCover,
    required this.horizontalPadding,
    required this.coverHeight,
    required this.coverWidth,
    required this.transitionComplete,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: context.colors.surfaceRaised),
          if (series.coverUrl.isNotEmpty) _blurredCover(),
          Container(color: context.colors.background.withValues(alpha: 0.2)),
          const _BottomFade(),
          if (showCover) _coverAndTitle(),
        ],
      ),
    );
  }

  Widget _blurredCover() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      opacity: transitionComplete ? 1.0 : 0.0,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: seriesBannerImage(
          series,
          // Decoded small: it is blurred past recognition, and a full-resolution banner is real memory.
          memCacheWidth: isWide ? 1200 : 800,
        ),
      ),
    );
  }

  Widget _coverAndTitle() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SeriesHeroCover(
                  series: series,
                  height: coverHeight,
                  width: coverWidth,
                  heroTagPrefix: heroTagPrefix,
                ),
                SizedBox(width: isWide ? 22 : 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SeriesTitleBlock(
                      series: series,
                      title: title,
                      isWide: isWide,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    final background = context.colors.background;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: 0.0),
            background.withValues(alpha: 0.4),
            background.withValues(alpha: 0.92),
            background,
          ],
          stops: const [0.25, 0.55, 0.85, 1.0],
        ),
      ),
    );
  }
}
