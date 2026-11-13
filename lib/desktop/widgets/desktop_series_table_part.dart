part of 'desktop_series_row.dart';

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

  /// A row's height for [style], grown with the OS text size so the title
  /// and its subtitle still fit when text is scaled up.
  static double rowHeight(
    AppListStyle style, [
    TextScaler textScaler = TextScaler.noScaling,
  ]) {
    final base = switch (style) {
      AppListStyle.comfortable => 88.0,
      AppListStyle.compact => 64.0,
      _ => 48.0,
    };
    final scale = textScaler.scale(14) / 14;
    return scale <= 1 ? base : base * scale;
  }

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
    final wanted = _wanted(style);
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

  /// How many of [style]'s columns a table of [width] shows — the only thing
  /// about the width a row or header needs to rebuild for.
  static int columnCount(
    AppListStyle style,
    double width, {
    required bool reserveAction,
  }) => columns(style, width, reserveAction: reserveAction).length;

  /// The first [count] of [style]'s columns.
  static List<DesktopSeriesColumn> firstColumns(
    AppListStyle style,
    int count,
  ) => _wanted(style).take(count).toList(growable: false);

  static List<DesktopSeriesColumn> _wanted(AppListStyle style) {
    return switch (style) {
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
  }
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
        return DerivedLayoutBuilder<int>(
          derive: (constraints) => DesktopSeriesTable.columnCount(
            style,
            constraints.maxWidth,
            reserveAction: reserveAction,
          ),
          builder: (context, count) {
            final columns = DesktopSeriesTable.firstColumns(style, count);

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
