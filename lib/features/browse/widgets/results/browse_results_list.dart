import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

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
        final activeStyle = settings.resolvedBrowseListStyle;
        final isGrid = activeStyle.isGrid;

        if (isGrid) {
          final columns = settings.resolvedBrowseGridColumnCount;

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
                    return const Center(child: MbSpinner());
                  }

                  final series = results[index];
                  return MbEntrance(
                    index: index,
                    child: MbTappable(
                      onTap: () => onSeriesTap(series),
                      pressedScale: 0.98,
                      child: shouldShowRanking
                          ? EntryListItem(
                              key: ValueKey('${activeStyle.name}_${series.id}'),
                              series: series,
                              ranking: index + 1,
                              heroTagPrefix: heroTagPrefix,
                              listStyle: activeStyle,
                            )
                          : EntryListItem(
                              key: ValueKey('${activeStyle.name}_${series.id}'),
                              series: series,
                              heroTagPrefix: heroTagPrefix,
                              listStyle: activeStyle,
                            ),
                    ),
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
                  return const Center(child: MbSpinner());
                }

                final series = results[index];
                return MbEntrance(
                  index: index,
                  child: MbTappable(
                    onTap: () => onSeriesTap(series),
                    pressedScale: 0.98,
                    child: shouldShowRanking
                        ? EntryListItem(
                            key: ValueKey('${activeStyle.name}_${series.id}'),
                            series: series,
                            ranking: index + 1,
                            heroTagPrefix: heroTagPrefix,
                            listStyle: activeStyle,
                          )
                        : EntryListItem(
                            key: ValueKey('${activeStyle.name}_${series.id}'),
                            series: series,
                            heroTagPrefix: heroTagPrefix,
                            listStyle: activeStyle,
                          ),
                  ),
                );
              },
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

        final list = ListView.builder(
          controller: scrollController,
          itemCount: results.length + (isLoading && results.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= results.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(child: MbSpinner()),
              );
            }

            final series = results[index];
            return InkWell(
              onTap: () => onSeriesTap(series),
              child: shouldShowRanking
                  ? EntryListItem(
                      key: ValueKey('${activeStyle.name}_${series.id}'),
                      series: series,
                      ranking: index + 1,
                      heroTagPrefix: heroTagPrefix,
                      listStyle: activeStyle,
                    )
                  : EntryListItem(
                      key: ValueKey('${activeStyle.name}_${series.id}'),
                      series: series,
                      heroTagPrefix: heroTagPrefix,
                      listStyle: activeStyle,
                    ),
            );
          },
        );

        // On desktop the list styles are tables, so they get column labels.
        if (!DesktopLayout.isActive(context)) return list;
        return Column(
          children: [
            DesktopSeriesListHeader(style: activeStyle),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}
