import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The sizes and offsets the series banner is laid out from.
///
/// They were a dozen bare numbers and nested ternaries inside one `build`,
/// where the relationships between them — that the leading width has to clear
/// the "Back" pill, that the title indent has to clear the cover — were
/// invisible. Gathering them here makes each one answerable on its own, and
/// keeps the two axes of variation (wide vs narrow, portrait vs landscape)
/// stated once.
class SeriesAppBarMetrics {
  /// True on a tablet- or desktop-width window.
  final bool isWide;

  final bool isLandscape;

  /// Width the sliver was actually given, used to centre content on very wide
  /// windows.
  final double layoutWidth;

  /// How far the page has scrolled under the app bar.
  final double scrollOffset;

  /// The screen's own horizontal inset, matching the page body.
  final double horizontalPadding;

  /// Whether the series is in the library — the delete control only exists
  /// then, and the title has to leave room for it.
  final bool hasEntry;

  /// Content stops widening here, matching the page body beneath.
  static const double _maxContentWidth = 1400;

  const SeriesAppBarMetrics({
    required this.isWide,
    required this.isLandscape,
    required this.layoutWidth,
    required this.scrollOffset,
    required this.horizontalPadding,
    required this.hasEntry,
  });

  /// Height of the banner before any scrolling. Landscape is shorter because
  /// the whole viewport is.
  double get expandedHeight {
    if (isWide) return isLandscape ? 330 : 380;
    return isLandscape ? 220 : 300;
  }

  double get coverHeight {
    if (isWide) return isLandscape ? 190 : 230;
    return isLandscape ? 140 : 172;
  }

  /// Standard book-cover proportions.
  double get coverWidth => coverHeight * 0.7;

  /// Slack either side once the window is wider than the content, so the app
  /// bar's controls line up with the body's edges instead of the window's.
  double get horizontalMargin =>
      math.max(0.0, (layoutWidth - _maxContentWidth) / 2);

  /// Opacity of the collapsed title, from 0 while the banner is open to 1 once
  /// it has collapsed to a toolbar.
  ///
  /// The fade starts partway down rather than immediately, so the small title
  /// does not appear while the large one below it is still fully readable.
  double get titleOpacity {
    final start = expandedHeight * 0.45;
    final end = expandedHeight - kToolbarHeight;
    return ((scrollOffset - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Whether the floating controls still need their glass background.
  ///
  /// Past the halfway fade they sit on the solid app bar, where a translucent
  /// pill reads as a stray box.
  bool get controlsNeedBackground => titleOpacity < 0.5;

  /// Space reserved for the leading control. Fixed rather than intrinsic, so
  /// the "Back" pill's label cannot shift the title as it appears.
  double get leadingWidth => (isWide ? 130 : 104) + horizontalMargin;

  /// Where the collapsed title starts — clear of the leading pill with balanced spacing.
  double get titleStartPadding => (isWide ? 138 : 112) + horizontalMargin;

  /// Where the collapsed title ends — clear of whichever trailing controls are
  /// present with balanced spacing matching the leading side.
  double get titleEndPadding {
    if (!showsBannerActions) return 16.0 + horizontalMargin;
    // Share alone, or share and delete.
    return (hasEntry ? 108.0 : 64.0) + horizontalMargin;
  }

  /// Whether share and delete appear on the banner itself.
  ///
  /// A wide portrait window has room for them in the layout below, so putting
  /// them on the banner too would duplicate them.
  bool get showsBannerActions => !(isWide && !isLandscape);
}
