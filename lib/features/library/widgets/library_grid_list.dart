import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_refresh_indicator.dart';

class LibraryGridList extends StatelessWidget {
  final List<LibraryEntry> items;
  final String tabKey;
  final ScrollController scrollController;
  final RefreshCallback onRefresh;
  final Function(api.Series) onItemTap;

  const LibraryGridList({
    super.key,
    required this.items,
    required this.tabKey,
    required this.scrollController,
    required this.onRefresh,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return MbRefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('no_results'),
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildList(context),
    );
  }

  /// Builds a single tappable library item with hover-prefetch for desktop.
  Widget _buildEntryItem(
    LibraryEntry entry,
    SeriesService seriesService,
    AppListStyle activeStyle,
  ) {
    return MouseRegion(
      onEnter: (_) => seriesService.fetchSeries(entry.series.id),
      child: GestureDetector(
        onTap: () => onItemTap(entry.series),
        // Use a library-scoped hero tag so the cover does NOT share the
        // 'series_cover_<id>' tag with the detail screen. That match would
        // trigger a Hero flight on top of the slideUp transition; the two
        // animations fight and drop frames (worst for top-of-list items,
        // whose flight overlaps the heavy app-bar region the whole way).
        // The slideUp already animates the cover into place on its own.
        child: EntryListItem(
          key: ValueKey('${activeStyle.name}_${entry.series.id}'),
          series: entry.series,
          isLibrary: true,
          heroTagPrefix: 'library',
          listStyle: activeStyle,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final settings = SettingsManager();
        final seriesService = getIt<SeriesService>();
        final activeStyle = settings.resolvedLibraryListStyle;
        final isGrid = activeStyle.isGrid;

        if (isGrid) {
          final columns = settings.resolvedLibraryGridColumnCount;

          final isCompactGrid = activeStyle == AppListStyle.compactGrid;

          Widget buildGridContent(BuildContext context, int calculatedColumns) {
            if (isCompactGrid) {
              return DynamicRowHeightGrid(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                crossAxisCount: calculatedColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                itemCount: items.length,
                itemBuilder: (context, index) => MbEntrance(
                  index: index,
                  child: _buildEntryItem(
                    items[index],
                    seriesService,
                    activeStyle,
                  ),
                ),
              );
            }

            return GridView.builder(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: columns > 0
                  ? SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: activeStyle.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    )
                  : SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: activeStyle.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
              itemCount: items.length,
              itemBuilder: (context, index) => MbEntrance(
                index: index,
                child: _buildEntryItem(
                  items[index],
                  seriesService,
                  activeStyle,
                ),
              ),
            );
          }

          if (columns == 0) {
            // Rebuilt only when the column count changes; between those a
            // resize just re-lays the grid out.
            return DerivedLayoutBuilder<int>(
              derive: (constraints) =>
                  ((constraints.maxWidth + 10) / 170).ceil().clamp(1, 12),
              builder: buildGridContent,
            );
          } else {
            Widget grid = buildGridContent(context, columns);
            final expectedWidth = columns * 160.0 + (columns - 1) * 10.0 + 24.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: expectedWidth),
                child: grid,
              ),
            );
          }
        }

        final list = ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) => MbEntrance(
            index: index,
            child: _buildEntryItem(items[index], seriesService, activeStyle),
          ),
        );

        // On desktop the list styles are tables, so they get column labels.
        if (!DesktopLayout.isActive(context)) return list;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DesktopSeriesListHeader(style: activeStyle),
            ),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}
