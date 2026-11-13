import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero_cover.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The full-bleed banner behind the series title: a heavily blurred cover,
/// a gradient that dissolves into the page background, and the cover artwork
/// and title block floating at its base.
class SeriesBannerBackground extends StatelessWidget {
  final Series series;
  final String title;

  final bool isWide;
  final bool showCover;
  final double horizontalPadding;
  final double coverHeight;
  final double coverWidth;
  final String? heroTagPrefix;

  /// Whether the route transition has settled.
  ///
  /// The blurred cover is held back until it has: an [ImageFiltered] blur over
  /// a full-width image is the most expensive thing on this page, and running
  /// it during the slide costs frames on exactly the devices that can least
  /// afford them.
  final bool transitionComplete;

  /// Content stops widening here, matching the page body beneath it, so the
  /// cover stays aligned with the cards below on a desktop window.
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
          // Decoded well under full size: it is blurred past recognition
          // anyway, and a full-resolution banner is real memory.
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

/// Dissolves the banner into the page background toward its base, so the
/// content below reads as continuing from it rather than butting against it.
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
          // Weighted late: the artwork stays legible through the top three
          // quarters and only then gives way.
          stops: const [0.25, 0.55, 0.85, 1.0],
        ),
      ),
    );
  }
}
