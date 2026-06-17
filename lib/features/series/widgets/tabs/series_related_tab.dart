import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';

class SeriesRelatedTab extends StatelessWidget {
  final List<Series>? related;
  final LocalizationService l10n;
  final double horizontalPadding;

  final String? currentSeriesId;
  final String? heroTagPrefix;

  const SeriesRelatedTab({
    super.key, 
    this.related, 
    required this.l10n,
    this.horizontalPadding = 16.0,
    this.currentSeriesId,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (related == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }
    // Filter out the current series and any duplicate IDs to prevent Hero tag collisions
    final uniqueRelated = <String, Series>{};
    for (final s in related!) {
      if (s.id != currentSeriesId) {
        uniqueRelated[s.id] = s;
      }
    }
    final finalRelated = uniqueRelated.values.toList();

    if (finalRelated.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_related_series'))));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          final style = settings.separateListStyles
              ? settings.browseListStyle
              : settings.currentListStyle;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeriesSectionHeader(title: l10n.translate('tab_related')),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (style.isGrid) {
                    return _buildGrid(context, settings, finalRelated, constraints.maxWidth);
                  }
                  return _buildList(context, finalRelated);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Series> series) {
    final seriesService = getIt<SeriesService>();
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final s = series[index];
        return MouseRegion(
          onEnter: (_) => seriesService.fetchSeries(s.id),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                AppTransitions.slideUp(SeriesDetailScreen(series: s)),
              );
            },
            child: EntryListItem(series: s, heroTagPrefix: heroTagPrefix),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, SettingsManager settings, List<Series> series, double maxWidth) {
    final seriesService = getIt<SeriesService>();
    final columnCount = settings.separateGridColumnCounts
        ? settings.browseGridColumnCount
        : settings.gridColumnCount;
    const spacing = 10.0;
    final cols = columnCount > 0 ? columnCount : (maxWidth / 160).floor().clamp(2, 6);
    final itemWidth = (maxWidth - spacing * (cols - 1)) / cols;
    final itemHeight = itemWidth / 0.65;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: series
          .map((s) => SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: MouseRegion(
                  onEnter: (_) => seriesService.fetchSeries(s.id),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        AppTransitions.slideUp(SeriesDetailScreen(series: s)),
                      );
                    },
                    child: EntryListItem(series: s, heroTagPrefix: heroTagPrefix),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
