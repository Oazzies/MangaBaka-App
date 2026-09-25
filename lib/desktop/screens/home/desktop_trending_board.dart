import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Trending as a chart: the #1 series featured large, the next places ranked
/// beside it, with the type and time-window controls in the header.
class DesktopTrendingBoard extends StatelessWidget {
  final List<Series> series;
  final bool loading;
  final String? selectedType;
  final int window;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback onViewAll;

  /// Ranked places shown beside the featured one.
  static const int _rankedCount = 8;

  /// Below this available width, the featured card and the ranked list
  /// stack vertically instead of sitting side by side — side by side, a
  /// narrow window left too little horizontal room for either half and
  /// they'd overflow rather than shrink.
  static const double _stackBreakpoint = 820;

  /// Below this, the stacked ranked list drops from two columns to one —
  /// two columns of title/meta text need more room than a narrow window
  /// has once the stacked layout is already using the full section width.
  static const double _twoColumnBreakpoint = 460;

  /// Height of the featured card and, separately, of the side-by-side
  /// layout as a whole.
  static const double _cardHeight = 420;

  /// Height of the featured card when it's stacked full-width above the
  /// ranked list instead of sitting in a narrower column beside it. Full
  /// width needs less height for the same content, and reusing
  /// [_cardHeight] there made the #1 card balloon to dominate the section
  /// — most of its visible "surface" — instead of reading as one entry
  /// above a list of others. Kept a real margin above the measured worst
  /// case (badge + 3-line title + meta + rating + a genre row, all at the
  /// narrowest text column this layout allows) rather than an exact fit —
  /// the description's leading gap is still reserved even when there's no
  /// room left to show any of it, and real font metrics vary slightly by
  /// platform, so a tight budget kept overflowing by a pixel or so.
  static const double _stackedCardHeight = 340;

  /// How much taller the fixed-height cards get with the OS text size: their
  /// heights are budgets for text, so a larger text size needs a larger one.
  static double _textGrowth(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 3.0);

  const DesktopTrendingBoard({
    super.key,
    required this.series,
    required this.loading,
    required this.selectedType,
    required this.window,
    required this.onTypeChanged,
    required this.onWindowChanged,
    required this.onViewAll,
  });

  static const List<(String?, String)> _types = [
    (null, 'any'),
    ('manga', 'type_manga'),
    ('manhwa', 'type_manhwa'),
    ('manhua', 'type_manhua'),
    ('novel', 'type_novel'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final grow = _textGrowth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DerivedLayoutBuilder<bool>(
          derive: (constraints) => constraints.maxWidth < _stackBreakpoint,
          builder: (context, stacked) => _header(context, l10n, stacked),
        ),
        // Rebuilt only when the layout changes shape (stacked or side by
        // side, one or two ranked columns); in between, a resize just
        // re-lays out what's built.
        DerivedLayoutBuilder<(bool, int)>(
          derive: (constraints) => (
            constraints.maxWidth < _stackBreakpoint,
            constraints.maxWidth < _twoColumnBreakpoint ? 1 : 2,
          ),
          builder: (context, shape) {
            final (stacked, columns) = shape;

            if (loading) {
              return _BoardSkeleton(stacked: stacked, grow: grow);
            }
            if (series.isEmpty) {
              return SizedBox(
                height: _cardHeight * grow,
                child: DesktopEmptyState(
                  icon: Icons.trending_up_rounded,
                  message: l10n.translate('no_results'),
                ),
              );
            }
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _stackedCardHeight * grow,
                    child: _FeaturedCard(series: series.first),
                  ),
                  const SizedBox(height: 16),
                  _rankedList(columns: columns),
                ],
              );
            }
            return SizedBox(
              height: _cardHeight * grow,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _FeaturedCard(series: series.first)),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: _rankedGridStretched()),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// The title plus the type/window/view-all controls. Below
  /// [_stackBreakpoint] the controls move onto their own line, wrapping
  /// onto a second row if even that isn't wide enough — [DesktopSectionTitle]
  /// lays out its title and trailing as a single [Wrap], which sizes each
  /// of the two as if it had unlimited width before deciding whether it
  /// fits; a trailing this wide reports that unlimited-width size back and
  /// overflows rather than actually shrinking. Giving it a line of its own
  /// inside a plain [Column] instead means the [Wrap] around the controls
  /// gets this section's real width to reflow within.
  Widget _header(BuildContext context, LocalizationService l10n, bool stacked) {
    final windowAndViewAll = [
      DesktopSegmented<int>(
        value: window,
        segments: const [(7, '7d', null), (30, '30d', null)],
        onChanged: onWindowChanged,
      ),
      DesktopPillButton(
        label: l10n.translate('view_all'),
        onPressed: onViewAll,
      ),
    ];

    if (!stacked) {
      return DesktopSectionTitle(
        title: l10n.translate('trending'),
        trailing: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            DesktopSegmented<String?>(
              value: selectedType,
              segments: [
                for (final (value, key) in _types)
                  (value, l10n.translate(key), null),
              ],
              onChanged: onTypeChanged,
            ),
            ...windowAndViewAll,
          ],
        ),
      );
    }

    // The 5-way type segmented control is, on its own, wider than a narrow
    // section — a Wrap can move it onto its own line but can't shrink a
    // single child to fit one, so unlike the other controls it needs an
    // actually-compact stand-in here rather than just room to reflow into.
    final typeLabel = l10n.translate(
      _types
          .firstWhere((t) => t.$1 == selectedType, orElse: () => _types.first)
          .$2,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trending').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              DesktopMenuButton<String?>(
                valueLabel: typeLabel,
                items: [
                  for (final (value, key) in _types)
                    (value, l10n.translate(key)),
                ],
                selected: selectedType,
                onSelected: onTypeChanged,
              ),
              ...windowAndViewAll,
            ],
          ),
        ],
      ),
    );
  }

  /// The ranked places as one or two columns, each sized to its own
  /// natural content height rather than stretched to fill a fixed height —
  /// the stacked layout doesn't hand this a bounded height to stretch
  /// into, unlike [_rankedGridStretched]'s side-by-side layout.
  Widget _rankedList({required int columns}) {
    final ranked = series.skip(1).take(_rankedCount).toList();
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < ranked.length; i++)
            _RankedRow(series: ranked[i], rank: i + 2),
        ],
      );
    }

    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      final row = _RankedRow(series: ranked[i], rank: i + 2);
      (i < _rankedCount / 2 ? left : right).add(row);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right,
          ),
        ),
      ],
    );
  }

  /// The ranked places as two columns stretched to fill [_cardHeight] —
  /// requires a bounded incoming height (see [_rankedList] for the version
  /// that doesn't).
  Widget _rankedGridStretched() {
    final ranked = series.skip(1).take(_rankedCount).toList();
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      final row = Expanded(
        child: _RankedRow(series: ranked[i], rank: i + 2),
      );
      (i < _rankedCount / 2 ? left : right).add(row);
    }
    // Pad short columns so rows keep the same height either side.
    while (left.length < _rankedCount / 2) {
      left.add(const Spacer());
    }
    while (right.length < _rankedCount / 2) {
      right.add(const Spacer());
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Series series;

  const _FeaturedCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = series.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );
    final rating = double.tryParse(series.rating) ?? 0;
    final meta = [
      if (series.type.isNotEmpty) l10n.translate('type_${series.type}'),
      if (series.year.isNotEmpty) series.year,
      if (series.status.isNotEmpty) l10n.translate('status_${series.status}'),
    ].join('  ·  ');
    final metadata = getIt<MetadataService>();

    return DesktopHoverSurface(
      onTap: () => openSeriesDetail(context, series, heroTag: 'trending_1'),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The cover, blurred, as a backdrop — the colour of the book
            // carries into the card without competing with the text. The
            // blur comes from decoding it tiny and stretching it: a blur
            // filter re-ran over the whole card on every frame it changed
            // size, and at this size nothing recognisable survives either
            // way.
            Opacity(
              opacity: 0.35,
              child: WidgetUtils.networkImage(
                url: series.coverUrl,
                memCacheWidth: 24,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.colors.background.withValues(alpha: 0.3),
                    context.colors.background.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              // The cover's width is a clamped share of the card's, so it
              // shrinks with a narrow card instead of overflowing it. Worked
              // out by the layout delegate: resizing never rebuilds the card.
              child: CustomMultiChildLayout(
                delegate: _FeaturedLayout(),
                children: [
                  LayoutId(
                    id: _FeaturedSlot.cover,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: WidgetUtils.networkImage(
                          url: series.coverUrl,
                          blurred: WidgetUtils.isRatingBlurred(
                            series.contentRating,
                          ),
                          memCacheWidth: 500,
                        ),
                      ),
                    ),
                  ),
                  LayoutId(
                    id: _FeaturedSlot.info,
                    // A hair of clip room: the elements below are
                    // sized to fit their budget by construction, but
                    // real font-metric rounding can still leave this
                    // column a sub-pixel taller than what it's given
                    // — clip that silently instead of throwing a
                    // debug-mode overflow error over less than a
                    // pixel.
                    child: ClipRect(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.accent,
                              borderRadius: BorderRadius.circular(
                                AppConstants.pillRadius,
                              ),
                            ),
                            child: Text(
                              '#1 ${l10n.translate('trending')}'.toUpperCase(),
                              style: AppTypography.display(
                                color: context.colors.onAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title.toUpperCase(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display(
                              color: context.colors.text,
                              fontSize: 28,
                              height: 1.1,
                            ),
                          ),
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(
                                color: context.colors.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (rating > 0) ...[
                            const SizedBox(height: 10),
                            MbRatingStars(
                              rating: rating,
                              outOf: 100,
                              fontSize: 14,
                            ),
                          ],
                          if (series.genres.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            // Capped to one row and clipped rather than
                            // left free to wrap to a second: at the
                            // narrowest widths, a fixed-size text column
                            // (see coverWidth above) can leave too little
                            // room for 4 chips on one line, and an
                            // uncapped second row was overflowing the
                            // card's fixed height below.
                            SizedBox(
                              height: 30,
                              child: ClipRect(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final g in series.genres.take(4))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.colors.surfaceRaised
                                              .withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.pillRadius,
                                          ),
                                        ),
                                        child: Text(
                                          metadata.getGenreLabel(g),
                                          style: AppTypography.sans(
                                            color: context.colors.text,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (series.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Expanded(
                              child: Text(
                                series.description,
                                overflow: TextOverflow.fade,
                                style: AppTypography.sans(
                                  color: context.colors.text.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontSize: 13.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FeaturedSlot { cover, info }

/// Cover on the left at a clamped share of the width, the details filling
/// the rest.
class _FeaturedLayout extends MultiChildLayoutDelegate {
  static const double _gap = 24;

  @override
  void performLayout(Size size) {
    final coverWidth = (size.width * 0.36).clamp(90.0, 200.0);
    // Loose: the 2:3 cover takes its height from this width, shrinking
    // only if the card is too short for it.
    layoutChild(
      _FeaturedSlot.cover,
      BoxConstraints(maxWidth: coverWidth, maxHeight: size.height),
    );
    positionChild(_FeaturedSlot.cover, Offset.zero);
    final infoLeft = coverWidth + _gap;
    layoutChild(
      _FeaturedSlot.info,
      BoxConstraints.tight(
        Size(math.max(0, size.width - infoLeft), size.height),
      ),
    );
    positionChild(_FeaturedSlot.info, Offset(infoLeft, 0));
  }

  @override
  bool shouldRelayout(_FeaturedLayout oldDelegate) => false;
}

class _RankedRow extends StatelessWidget {
  final Series series;
  final int rank;

  const _RankedRow({required this.series, required this.rank});

  /// Fixed rather than derived from the row's height (as a bare
  /// [AspectRatio] would): in the two-column wide layout this row can sit
  /// inside an [Expanded] whose height varies with the window, and in the
  /// single-column stacked layout it isn't height-constrained at all — an
  /// ambient height in either case is either the wrong thing to size the
  /// cover from or isn't there to use.
  static const double _coverWidth = 46;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = series.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );
    final rating = double.tryParse(series.rating) ?? 0;
    final meta = [
      if (series.type.isNotEmpty) l10n.translate('type_${series.type}'),
      if (series.year.isNotEmpty) series.year,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DesktopHoverSurface(
        onTap: () =>
            openSeriesDetail(context, series, heroTag: 'trending_$rank'),
        idleColor: context.colors.surface,
        hoverColor: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '$rank',
                style: AppTypography.display(
                  color: rank <= 3
                      ? context.colors.accent
                      : context.colors.textMuted,
                  fontSize: 22,
                ),
              ),
            ),
            SizedBox(
              width: _coverWidth,
              height: _coverWidth * 1.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: WidgetUtils.networkImage(
                  url: series.coverUrl,
                  blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                  memCacheWidth: 120,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(width: 10),
              MbRatingStars(rating: rating, outOf: 100, fontSize: 11),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardSkeleton extends StatelessWidget {
  final bool stacked;
  final double grow;

  const _BoardSkeleton({required this.stacked, required this.grow});

  @override
  Widget build(BuildContext context) {
    Widget block() => Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    if (stacked) {
      return Shimmer.fromColors(
        baseColor: context.colors.surfaceRaised,
        highlightColor: context.colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: DesktopTrendingBoard._stackedCardHeight * grow,
              child: block(),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SizedBox(height: 69, child: block()),
            ],
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: context.colors.surfaceRaised,
      highlightColor: context.colors.surface,
      child: SizedBox(
        height: DesktopTrendingBoard._cardHeight * grow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: block()),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Expanded(child: block()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
