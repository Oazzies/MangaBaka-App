import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

class SeriesSimilarGrid extends StatelessWidget {
  final List<Series> series;
  final AppListStyle style;
  final String heroTagPrefix;
  final SeriesListDeps deps;

  const SeriesSimilarGrid({
    super.key,
    required this.series,
    required this.style,
    required this.heroTagPrefix,
    required this.deps,
  });

  @override
  Widget build(BuildContext context) {
    final isCompactGrid = style == AppListStyle.compactGrid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final calculatedColumns = ((constraints.maxWidth + 16) / 166)
            .ceil()
            .clamp(1, 12);
        if (isCompactGrid) {
          return DynamicRowHeightGrid(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: calculatedColumns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            itemCount: series.length,
            itemBuilder: (context, index) => _buildCard(context, series[index]),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: series.length,
          itemBuilder: (context, index) => _buildCard(context, series[index]),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Series s) {
    return MouseRegion(
      onEnter: (_) => deps.prefetch(s.id),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            AppTransitions.slideUp(
              SeriesDetailScreen(series: s, heroTagPrefix: heroTagPrefix),
            ),
          );
        },
        child: EntryListItem(
          series: s,
          deps: deps,
          heroTagPrefix: heroTagPrefix,
          listStyle: style,
        ),
      ),
    );
  }
}
