import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';

class BrowseResultsList extends StatelessWidget {
  final List<Series> results;
  final ScrollController scrollController;
  final bool isLoading;
  final bool shouldShowRanking;
  final Function(Series) onSeriesTap;
  final String? heroTagPrefix;

  const BrowseResultsList({
    required this.results,
    required this.scrollController,
    required this.isLoading,
    required this.shouldShowRanking,
    required this.onSeriesTap,
    this.heroTagPrefix,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final settings = SettingsManager();
        final activeStyle = settings.separateListStyles
            ? settings.browseListStyle
            : settings.currentListStyle;
        final isGrid = activeStyle.isGrid;

        if (isGrid) {
          final columns = settings.separateGridColumnCounts
              ? settings.browseGridColumnCount
              : settings.gridColumnCount;

          final isCompactGrid = activeStyle == AppListStyle.compactGrid;

          Widget buildGridContent(BuildContext context, int calculatedColumns) {
            final itemCount = results.length + (isLoading && results.isNotEmpty ? 1 : 0);

            if (isCompactGrid) {
              return DynamicRowHeightGrid(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                crossAxisCount: calculatedColumns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= results.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final series = results[index];
                  return InkWell(
                    onTap: () => onSeriesTap(series),
                    child: shouldShowRanking
                        ? EntryListItem(series: series, ranking: index + 1, heroTagPrefix: heroTagPrefix)
                        : EntryListItem(series: series, heroTagPrefix: heroTagPrefix),
                  );
                },
              );
            }

            return GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= results.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final series = results[index];
                return InkWell(
                  onTap: () => onSeriesTap(series),
                  child: shouldShowRanking
                      ? EntryListItem(series: series, ranking: index + 1, heroTagPrefix: heroTagPrefix)
                      : EntryListItem(series: series, heroTagPrefix: heroTagPrefix),
                );
              },
            );
          }

          if (columns == 0) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final calculatedColumns = ((width + 10) / 170).ceil().clamp(1, 12);
                return buildGridContent(context, calculatedColumns);
              },
            );
          } else {
            Widget grid = buildGridContent(context, columns);
            final expectedWidth = columns * 160.0 + (columns - 1) * 10.0;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: expectedWidth),
                child: grid,
              ),
            );
          }
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: results.length + (isLoading && results.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= results.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final series = results[index];
            return InkWell(
              onTap: () => onSeriesTap(series),
              child: shouldShowRanking
                  ? EntryListItem(series: series, ranking: index + 1, heroTagPrefix: heroTagPrefix)
                  : EntryListItem(series: series, heroTagPrefix: heroTagPrefix),
            );
          },
        );
      },
    );
  }
}
