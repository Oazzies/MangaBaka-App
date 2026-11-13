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

part 'desktop_trending_featured_part.dart';
part 'desktop_trending_rows_part.dart';

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
  /// stack vertically instead of sitting side by side â€” side by side, a
  /// narrow window left too little horizontal room for either half and
  /// they'd overflow rather than shrink.
  static const double _stackBreakpoint = 820;

  /// Below this, the stacked ranked list drops from two columns to one â€”
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
  /// â€” most of its visible "surface" â€” instead of reading as one entry
  /// above a list of others. Kept a real margin above the measured worst
  /// case (badge + 3-line title + meta + rating + a genre row, all at the
  /// narrowest text column this layout allows) rather than an exact fit â€”
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
  /// onto a second row if even that isn't wide enough â€” [DesktopSectionTitle]
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
    // section â€” a Wrap can move it onto its own line but can't shrink a
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
  /// natural content height rather than stretched to fill a fixed height â€”
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

  Widget _rankedGridStretched() =>
      _RankedGridStretched(series: series, rankedCount: _rankedCount);
}
