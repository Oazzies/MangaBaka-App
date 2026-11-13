import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_series_table_part.dart';

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
    final height = DesktopSeriesTable.rowHeight(
      _style,
      MediaQuery.textScalerOf(context),
    );
    final coverWidth = DesktopSeriesTable.coverWidth(_style);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // Rebuilt only when a column appears or drops away; between those a
      // resize just re-lays the row out.
      child: DerivedLayoutBuilder<int>(
        derive: (constraints) => DesktopSeriesTable.columnCount(
          _style,
          constraints.maxWidth,
          reserveAction: reserveAction,
        ),
        builder: (context, count) {
          final columns = DesktopSeriesTable.firstColumns(_style, count);

          // Only the hover fill animates; the height is set outright.
          return SizedBox(
            height: height,
            child: AnimatedContainer(
              duration: AppMotion.fast,
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
