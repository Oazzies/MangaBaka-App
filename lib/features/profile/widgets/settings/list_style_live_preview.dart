import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';

/// Mock entry, not the user's own: it must render on an empty library and show every state.
class ListStyleLivePreview extends StatelessWidget {
  final AppListStyle style;
  final bool showLibraryProgress;
  final bool showRemainingProgress;
  final LibraryProgressType progressType;

  /// 0 means "auto", matching [SettingsManager.gridColumnCount].
  final int gridColumnCount;
  final SeriesListDeps deps;

  static const double _autoColumnExtent = 170;
  static const double _maxCellWidth = 160;
  static const double _cellSpacing = 10;

  const ListStyleLivePreview({
    super.key,
    required this.style,
    required this.showLibraryProgress,
    required this.showRemainingProgress,
    required this.progressType,
    required this.gridColumnCount,
    required this.deps,
  });

  static final LibraryEntry _mockEntry = LibraryEntry(
    id: '222',
    state: 'reading',
    progressChapter: 5,
    progressVolume: 1,
    series: mockSeries222,
  );

  @override
  Widget build(BuildContext context) {
    if (!style.isGrid) {
      if (!DesktopLayout.isActive(context)) return _item(0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesktopSeriesListHeader(style: style),
          for (var i = 0; i < 3; i++) _item(i),
        ],
      );
    }

    if (gridColumnCount == 0) {
      return DerivedLayoutBuilder<int>(
        derive: (constraints) =>
            ((constraints.maxWidth + _cellSpacing) / _autoColumnExtent)
                .ceil()
                .clamp(1, 12),
        builder: (context, columns) => _grid(columns),
      );
    }

    // Capped to the columns' real width, or two columns stretch across a desktop window.
    final width =
        gridColumnCount * _maxCellWidth +
        (gridColumnCount - 1) * _cellSpacing +
        24.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: _grid(gridColumnCount),
      ),
    );
  }

  Widget _grid(int columns) {
    final itemCount = columns > 0 ? columns : 3;

    if (style == AppListStyle.compactGrid) {
      return DynamicRowHeightGrid(
        // responsive-ok: a preview of at most a row of items.
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        crossAxisCount: itemCount,
        crossAxisSpacing: _cellSpacing,
        mainAxisSpacing: _cellSpacing,
        itemCount: itemCount,
        itemBuilder: (context, index) => _item(index),
      );
    }

    return GridView.builder(
      // responsive-ok: a preview of at most a row of items.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: gridColumnCount > 0
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumnCount,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: _cellSpacing,
              mainAxisSpacing: _cellSpacing,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _maxCellWidth,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: _cellSpacing,
              mainAxisSpacing: _cellSpacing,
            ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _item(index),
    );
  }

  Widget _item(int index) => EntryListItem(
    series: mockSeries222,
    deps: deps,
    isLibrary: true,
    listStyle: style,
    // Unique per cell: duplicate Hero tags would collide with each other and real list items.
    heroTagPrefix: 'preview_${style.name}_$index',
    previewEntry: _mockEntry,
  );
}
