import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A column of the desktop series table.
enum DesktopSeriesColumn {
  type(96, 'type'),
  status(112, 'status'),
  year(64, 'year'),
  rating(88, 'rating'),
  chapters(88, 'chapters');

  final double width;
  final String labelKey;

  const DesktopSeriesColumn(this.width, this.labelKey);
}

/// Sizing shared by [DesktopSeriesRow] and [DesktopSeriesListHeader], so the
/// header's labels sit exactly over the rows' cells.
abstract final class DesktopSeriesTable {
  /// Horizontal inset of a row's content.
  static const double sidePadding = 12;

  /// Gap between the cover and the title.
  static const double coverGap = 14;

  /// Room at the right edge for the "12 / 200  +1" quick-progress control.
  static const double actionWidth = 148;

  /// The narrowest a title may get before columns start being dropped.
  static const double minTitleWidth = 220;

  static double rowHeight(AppListStyle style) => switch (style) {
    AppListStyle.comfortable => 88,
    AppListStyle.compact => 64,
    _ => 48,
  };

  static double coverWidth(AppListStyle style) => switch (style) {
    AppListStyle.comfortable => 48,
    AppListStyle.compact => 36,
    _ => 28,
  };

  /// Left edge of the title cell, from the row's own left edge.
  static double titleLeft(AppListStyle style) =>
      sidePadding + coverWidth(style) + coverGap;

  /// The columns a table of [width] shows for [style], most important first.
  ///
  /// Denser styles carry fewer facts; and whatever the style, columns are
  /// dropped from the right as the window narrows so the title keeps its room.
  static List<DesktopSeriesColumn> columns(
    AppListStyle style,
    double width, {
    required bool reserveAction,
  }) {
    final wanted = switch (style) {
      AppListStyle.comfortable => DesktopSeriesColumn.values,
      AppListStyle.compact => const [
        DesktopSeriesColumn.type,
        DesktopSeriesColumn.status,
        DesktopSeriesColumn.year,
        DesktopSeriesColumn.rating,
      ],
      _ => const [
        DesktopSeriesColumn.type,
        DesktopSeriesColumn.status,
        DesktopSeriesColumn.year,
      ],
    };

    var room =
        width -
        titleLeft(style) -
        sidePadding -
        minTitleWidth -
        (reserveAction ? actionWidth : 0);
    final shown = <DesktopSeriesColumn>[];
    for (final column in wanted) {
      if (room < column.width) break;
      shown.add(column);
      room -= column.width;
    }
    return shown;
  }
}

/// A series as one row of a table — cover, title, and its facts in aligned
/// columns.
///
/// The phone's list rows are cards sized for a thumb, with the facts run
/// together on one muted line; on a wide window that wastes the width and makes
/// a long list hard to scan. Here each fact has its own column, so a list can
/// be read down as well as across.
class DesktopSeriesRow extends StatefulWidget {
  final Series series;
  final AppListStyle style;
  final String displayTitle;
  final String? heroTagPrefix;

  /// A thin bar drawn under the title, for a series with library progress.
  final Widget? progress;

  /// The quick-progress control, aligned in the row's right-hand gutter.
  final Widget? trailing;

  const DesktopSeriesRow({
    super.key,
    required this.series,
    required this.style,
    required this.displayTitle,
    this.heroTagPrefix,
    this.progress,
    this.trailing,
  });

  @override
  State<DesktopSeriesRow> createState() => _DesktopSeriesRowState();
}

class _DesktopSeriesRowState extends State<DesktopSeriesRow> {
  bool _hovered = false;

  Series get _series => widget.series;
  AppListStyle get _style => widget.style;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final reserveAction = SettingsManager().showQuickProgress;
    final height = DesktopSeriesTable.rowHeight(_style);
    final coverWidth = DesktopSeriesTable.coverWidth(_style);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = DesktopSeriesTable.columns(
            _style,
            constraints.maxWidth,
            reserveAction: reserveAction,
          );

          return AnimatedContainer(
            duration: AppMotion.fast,
            height: height,
            padding: const EdgeInsets.symmetric(
              horizontal: DesktopSeriesTable.sidePadding,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _hovered ? context.colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                EntryListLayoutHelper.buildCoverImage(
                  series: _series,
                  heroTagPrefix: widget.heroTagPrefix,
                  width: coverWidth,
                  height: height - 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: DesktopSeriesTable.coverGap),
                Expanded(child: _titleCell(l10n)),
                for (final column in columns)
                  SizedBox(width: column.width, child: _cell(column, l10n)),
                if (reserveAction)
                  SizedBox(
                    width: DesktopSeriesTable.actionWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: widget.trailing,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _titleCell(LocalizationService l10n) {
    final subtitle = _series.authors.isNotEmpty
        ? _series.authors.take(3).join(', ')
        : '';
    final showSubtitle =
        _style != AppListStyle.minimalList && subtitle.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: _style == AppListStyle.comfortable ? 15.5 : 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
          if (widget.progress != null) ...[
            const SizedBox(height: 6),
            widget.progress!,
          ],
        ],
      ),
    );
  }

  Widget _cell(DesktopSeriesColumn column, LocalizationService l10n) {
    switch (column) {
      case DesktopSeriesColumn.rating:
        final rating = double.tryParse(_series.rating) ?? 0;
        return Align(
          alignment: Alignment.centerLeft,
          child: rating > 0
              ? MbRatingStars(rating: rating, fontSize: 13)
              : _text('—'),
        );
      case DesktopSeriesColumn.type:
        return _text(_translated(l10n, 'type_', _series.type));
      case DesktopSeriesColumn.status:
        return _text(_translated(l10n, 'status_', _series.status));
      case DesktopSeriesColumn.year:
        final year = _series.year;
        return _text(year.isEmpty || year == '0' ? '—' : year);
      case DesktopSeriesColumn.chapters:
        final chapters = _series.totalChapters;
        return _text(chapters.isEmpty || chapters == '0' ? '—' : chapters);
    }
  }

  /// The translated value, or the raw one when the API sent something the
  /// language files do not know.
  String _translated(LocalizationService l10n, String prefix, String value) {
    if (value.isEmpty) return '—';
    final key = '$prefix${value.toLowerCase()}';
    final translated = l10n.translate(key);
    return translated == key ? value : translated;
  }

  Widget _text(String value) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.sans(
        color: context.colors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// The label row above a desktop series table.
///
/// Uses the same [DesktopSeriesTable] sizing as the rows, so each label sits
/// over its column. Hosts place it in the same horizontal inset as the list.
class DesktopSeriesListHeader extends StatelessWidget {
  final AppListStyle style;

  const DesktopSeriesListHeader({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final reserveAction = SettingsManager().showQuickProgress;
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = DesktopSeriesTable.columns(
              style,
              constraints.maxWidth,
              reserveAction: reserveAction,
            );

            return Container(
              height: 34,
              padding: const EdgeInsets.symmetric(
                horizontal: DesktopSeriesTable.sidePadding,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.colors.border),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width:
                        DesktopSeriesTable.coverWidth(style) +
                        DesktopSeriesTable.coverGap,
                  ),
                  Expanded(
                    child: _label(context, l10n.translate('column_title')),
                  ),
                  for (final column in columns)
                    SizedBox(
                      width: column.width,
                      child: _label(context, l10n.translate(column.labelKey)),
                    ),
                  if (reserveAction)
                    const SizedBox(width: DesktopSeriesTable.actionWidth),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _label(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.monoLabel(
        color: context.colors.textMuted,
        fontSize: 11,
      ),
    ),
  );
}
