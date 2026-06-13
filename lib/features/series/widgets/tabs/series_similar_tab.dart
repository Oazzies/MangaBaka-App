import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SeriesSectionHeader(
                      title: l10n.translate('tab_similar'),
                      bottomPadding: 0,
                    ),
                  ),
                  WidgetUtils.tooltip(
                    message: l10n.translate('toggle_layout'),
                    child: IconButton(
                      icon: Icon(
                        style.next.icon,
                        color: AppConstants.textColor,
                      ),
                      onPressed: () => settings.setSimilarListStyle(style.next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (style.isGrid) {
                    return _buildGrid(settings, filtered, constraints.maxWidth);
                  }
                  return _buildList(filtered);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Series> series) {
    // Lay out items directly in a Column rather than a nested non-scrolling
    // ListView: inside the detail screen's AnimatedSwitcher transition the
    // ListView's overscroll viewport can be painted before layout completes,
    // throwing "RenderBox was not laid out" / "Cannot hit test ... no size".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in series)
          EntryListItem(series: s, heroTagPrefix: 'similar'),
      ],
    );
  }

  Widget _buildGrid(SettingsManager settings, List<Series> series, double maxWidth) {
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
                child: EntryListItem(series: s, heroTagPrefix: 'similar'),
              ))
          .toList(),
    );
  }
}
