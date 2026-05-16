import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';

class BrowseResultsList extends StatelessWidget {
  final List<Series> results;
  final ScrollController scrollController;
  final bool isLoading;
  final bool shouldShowRanking;
  final Function(Series) onSeriesTap;

  const BrowseResultsList({
    required this.results,
    required this.scrollController,
    required this.isLoading,
    required this.shouldShowRanking,
    required this.onSeriesTap,
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

          Widget grid = GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            gridDelegate: columns > 0
                ? SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  )
                : const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
            itemCount: results.length + (isLoading && results.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= results.length) {
                return const Center(child: CircularProgressIndicator());
              }

              final series = results[index];
              return InkWell(
                onTap: () => onSeriesTap(series),
                child: shouldShowRanking
                    ? EntryListItem(series: series, ranking: index + 1)
                    : EntryListItem(series: series),
              );
            },
          );

          if (columns > 0) {
            final expectedWidth = columns * 160.0 + (columns - 1) * 10.0;
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
                  ? EntryListItem(series: series, ranking: index + 1)
                  : EntryListItem(series: series),
            );
          },
        );
      },
    );
  }
}
