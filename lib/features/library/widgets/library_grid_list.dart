import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';

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

    return RefreshIndicator(
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
                          color: AppConstants.textMutedColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('no_results'),
                          style: TextStyle(
                            color: AppConstants.textMutedColor,
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
  Widget _buildEntryItem(LibraryEntry entry, SeriesService seriesService) {
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
          series: entry.series,
          isLibrary: true,
          heroTagPrefix: 'library',
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
        final activeStyle = settings.separateListStyles
            ? settings.libraryListStyle
            : settings.currentListStyle;
        final isGrid = activeStyle.isGrid;

        if (isGrid) {
          final columns = settings.separateGridColumnCounts
              ? settings.libraryGridColumnCount
              : settings.gridColumnCount;

          Widget grid = GridView.builder(
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
            itemBuilder: (context, index) =>
                _buildEntryItem(items[index], seriesService),
          );

          if (columns > 0) {
            final expectedWidth = columns * 160.0 + (columns - 1) * 10.0 + 24.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: expectedWidth),
                child: grid,
              ),
            );
          }

          return grid;
        }

        return ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildEntryItem(items[index], seriesService),
        );
      },
    );
  }
}
