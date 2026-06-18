import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/widgets/dynamic_row_height_grid.dart';

class SeriesSimilarTab extends StatelessWidget {
  final List<Series>? similar;
  final LocalizationService l10n;
  final double horizontalPadding;
  final String? currentSeriesId;

  const SeriesSimilarTab({
    super.key,
    required this.similar,
    required this.l10n,
    this.horizontalPadding = 16.0,
    this.currentSeriesId,
  });

  @override
  Widget build(BuildContext context) {
    if (similar == null) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final unique = <String, Series>{};
    for (final s in similar!) {
      if (s.id != currentSeriesId) {
        unique[s.id] = s;
      }
    }
    final filtered = unique.values.toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text(l10n.translate('no_similar_series'))),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          final style = settings.similarListStyle;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    SeriesSectionHeader(title: l10n.translate('tab_similar')),
                    Positioned(
                      right: 0,
                      top: -12,
                      child: WidgetUtils.tooltip(
                        message: l10n.translate('toggle_layout'),
                        child: IconButton(
                          icon: Icon(
                            style.next.icon,
                            color: AppConstants.textColor,
                          ),
                          onPressed: () => settings.setSimilarListStyle(style.next),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (style.isGrid)
                _buildGrid(context, filtered, style)
              else
                _buildList(context, filtered, style),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Series> series, AppListStyle style) {
    // Lay out items directly in a Column rather than a nested non-scrolling
    // ListView: inside the detail screen's AnimatedSwitcher transition the
    // ListView's overscroll viewport can be painted before layout completes,
    // throwing "RenderBox was not laid out" / "Cannot hit test ... no size".
    final seriesService = getIt<SeriesService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in series)
          MouseRegion(
            onEnter: (_) => seriesService.fetchSeries(s.id),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  AppTransitions.slideUp(SeriesDetailScreen(
                    series: s,
                    heroTagPrefix: 'similar',
                  )),
                );
              },
              child: EntryListItem(
                series: s,
                heroTagPrefix: 'similar',
                listStyle: style,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<Series> series, AppListStyle style) {
    final seriesService = getIt<SeriesService>();
    final isCompactGrid = style == AppListStyle.compactGrid;

    Widget buildGridContent(BuildContext context, int calculatedColumns) {
      if (isCompactGrid) {
        return DynamicRowHeightGrid(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: calculatedColumns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          itemCount: series.length,
          itemBuilder: (context, index) {
            final s = series[index];
            return MouseRegion(
              onEnter: (_) => seriesService.fetchSeries(s.id),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.slideUp(SeriesDetailScreen(
                      series: s,
                      heroTagPrefix: 'similar',
                    )),
                  );
                },
                child: EntryListItem(
                  series: s,
                  heroTagPrefix: 'similar',
                  listStyle: style,
                ),
              ),
            );
          },
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
        itemBuilder: (context, index) {
          final s = series[index];
          return MouseRegion(
            onEnter: (_) => seriesService.fetchSeries(s.id),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  AppTransitions.slideUp(SeriesDetailScreen(
                    series: s,
                    heroTagPrefix: 'similar',
                  )),
                );
              },
              child: EntryListItem(
                series: s,
                heroTagPrefix: 'similar',
                listStyle: style,
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final calculatedColumns = ((width + 16) / 166).ceil().clamp(1, 12);
        return buildGridContent(context, calculatedColumns);
      },
    );
  }
}
