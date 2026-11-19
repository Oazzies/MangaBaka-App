import 'dart:math' as math;

import 'package:flutter/material.dart';

class SeriesAppBarMetrics {
  final bool isWide;

  final bool isLandscape;

  final double layoutWidth;

  final double scrollOffset;

  final double horizontalPadding;

  final bool hasEntry;

  /// Must match the page body's max content width.
  static const double _maxContentWidth = 1400;

  const SeriesAppBarMetrics({
    required this.isWide,
    required this.isLandscape,
    required this.layoutWidth,
    required this.scrollOffset,
    required this.horizontalPadding,
    required this.hasEntry,
  });

  double get expandedHeight {
    if (isWide) return isLandscape ? 330 : 380;
    return isLandscape ? 220 : 300;
  }

  double get coverHeight {
    if (isWide) return isLandscape ? 190 : 230;
    return isLandscape ? 140 : 172;
  }

  double get coverWidth => coverHeight * 0.7;

  double get horizontalMargin =>
      math.max(0.0, (layoutWidth - _maxContentWidth) / 2);

  /// Starts at 45% so the small title never appears while the large one is still readable.
  double get titleOpacity {
    final start = expandedHeight * 0.45;
    final end = expandedHeight - kToolbarHeight;
    return ((scrollOffset - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Past the halfway fade a translucent pill on the solid app bar reads as a stray box.
  bool get controlsNeedBackground => titleOpacity < 0.5;

  /// Fixed, not intrinsic, so the "Back" pill's label cannot shift the title as it appears.
  double get leadingWidth => (isWide ? 130 : 104) + horizontalMargin;

  double get titleStartPadding => (isWide ? 138 : 112) + horizontalMargin;

  double get titleEndPadding {
    if (!showsBannerActions) return 16.0 + horizontalMargin;
    return (hasEntry ? 108.0 : 64.0) + horizontalMargin;
  }

  /// A wide portrait layout already shows share and delete below the banner.
  bool get showsBannerActions => !(isWide && !isLandscape);
}
