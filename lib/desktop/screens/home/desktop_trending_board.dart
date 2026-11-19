import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
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
import 'package:mangabaka_app/features/series/utils/series_labels.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_trending_featured_part.dart';
part 'desktop_trending_rows_part.dart';

class DesktopTrendingBoard extends StatelessWidget {
  final List<Series> series;
  final bool loading;
  final String? selectedType;
  final int window;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback onViewAll;
  final MetadataService metadata;

  static const int _rankedCount = 8;

  static const double _stackBreakpoint = 820;

  static const double _twoColumnBreakpoint = 460;

  static const double _cardHeight = 420;

  /// Reusing [_cardHeight] here made the #1 card dominate; kept above the measured worst case
  /// because font metrics vary by platform and a tight budget overflowed by a pixel.
  static const double _stackedCardHeight = 340;

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
    required this.metadata,
  });

  static const List<({String? value, String labelKey})> _types = [
    (value: null, labelKey: 'any'),
    (value: 'manga', labelKey: 'type_manga'),
    (value: 'manhwa', labelKey: 'type_manhwa'),
    (value: 'manhua', labelKey: 'type_manhua'),
    (value: 'novel', labelKey: 'type_novel'),
  ];

  static const List<int> _windows = [7, 30];

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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            height: 2,
            child: loading && series.isNotEmpty
                ? LinearProgressIndicator(
                    minHeight: 2,
                    color: context.colors.accent,
                    backgroundColor: Colors.transparent,
                  )
                : null,
          ),
        ),
        DerivedLayoutBuilder<(bool, int)>(
          derive: (constraints) => (
            constraints.maxWidth < _stackBreakpoint,
            constraints.maxWidth < _twoColumnBreakpoint ? 1 : 2,
          ),
          builder: (context, shape) {
            final (stacked, columns) = shape;

            if (series.isEmpty) {
              if (loading) return _BoardSkeleton(stacked: stacked, grow: grow);
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
                    child: _FeaturedCard(
                      series: series.first,
                      metadata: metadata,
                    ),
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
                  Expanded(
                    flex: 5,
                    child: _FeaturedCard(
                      series: series.first,
                      metadata: metadata,
                    ),
                  ),
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

  /// Stacked, the controls get their own line: [DesktopSectionTitle]'s single [Wrap] sizes a
  /// trailing this wide as if unbounded and overflows instead of shrinking it.
  Widget _header(BuildContext context, LocalizationService l10n, bool stacked) {
    final windowAndViewAll = [
      DesktopSegmented<int>(
        value: window,
        segments: [
          for (final days in _windows)
            (
              days,
              l10n
                  .translate('trending_window_days')
                  .replaceAll('{days}', '$days'),
              null,
            ),
        ],
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
        padding: EdgeInsets.zero,
        trailing: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            DesktopSegmented<String?>(
              value: selectedType,
              segments: [
                for (final type in _types)
                  (type.value, l10n.translate(type.labelKey), null),
              ],
              onChanged: onTypeChanged,
            ),
            ...windowAndViewAll,
          ],
        ),
      );
    }

    // A Wrap can't shrink one child, and the 5-way type control alone outgrows a narrow section.
    final typeLabel = l10n.translate(
      _types
          .firstWhere(
            (t) => t.value == selectedType,
            orElse: () => _types.first,
          )
          .labelKey,
    );

    return Column(
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
                for (final type in _types)
                  (type.value, l10n.translate(type.labelKey)),
              ],
              selected: selectedType,
              onSelected: onTypeChanged,
            ),
            ...windowAndViewAll,
          ],
        ),
      ],
    );
  }

  /// Natural height: unlike [_rankedGridStretched], the stacked layout gives no bounded height.
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
