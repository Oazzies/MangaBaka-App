import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';

/// A live sample of the chosen list style, built from the same
/// [EntryListItem] the real lists use so the preview cannot drift from them.
///
/// The entry is mock data rather than one of the user's own: the preview must
/// look the same on an empty library, and it renders states (progress, rating)
/// a given user may not have any example of.
class ListStyleLivePreview extends StatelessWidget {
  final AppListStyle style;
  final bool showLibraryProgress;
  final bool showRemainingProgress;
  final LibraryProgressType progressType;

  /// 0 means "auto", matching [SettingsManager.gridColumnCount].
  final int gridColumnCount;

  /// Width of one auto-sized grid cell plus its spacing, used to work out how
  /// many columns the available width fits.
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
      // On desktop the list styles are tables: show the column labels and a
      // few rows, so the density of the chosen style is actually visible.
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

    // With a fixed column count, cap the preview at the width those columns
    // would actually occupy — otherwise two columns stretch across a desktop
    // window and look nothing like the real list.
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

  /// One row of sample cells — enough to show the column rhythm without
  /// turning the preview into a page of its own.
  Widget _grid(int columns) {
    final itemCount = columns > 0 ? columns : 3;

    // The compact grid sizes rows to their tallest cell, so it needs the
    // dynamic-height grid rather than a fixed aspect ratio.
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
    isLibrary: true,
    listStyle: style,
    // Distinct per cell so the previews never collide with each other or
    // with a real list item in a Hero transition.
    heroTagPrefix: 'preview_${style.name}_$index',
    previewEntry: _mockEntry,
  );
}
