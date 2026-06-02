import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SeriesCollectionsTab extends StatelessWidget {
  final List<SeriesCollection>? collections;
  final double horizontalPadding;

  const SeriesCollectionsTab({
    super.key, 
    this.collections,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (collections == null) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    final l10n = LocalizationService();
    if (collections!.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_collections_available'))));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SeriesSectionHeader(
                      title: l10n.translate('tab_collections'),
                      bottomPadding: 0,
                    ),
                  ),
                  if (MediaQuery.of(context).orientation == Orientation.landscape)
                    _buildColumnSwitch(context, settings),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                  final prefColumns = settings.collectionsListColumns;
                  
                  // Double column support is only for landscape mode.
                  // In portrait, we always use 1 column.
                  // In landscape, we use 2 unless the user specifically chose 1.
                  final columns = isLandscape 
                      ? (prefColumns == 1 ? 1 : 2)
                      : 1;

                  final spacing = 12.0;
                  final itemWidth = columns > 1 
                      ? (constraints.maxWidth - (spacing * (columns - 1))) / columns 
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: collections!.map((col) => SizedBox(
                      width: itemWidth,
                      child: _buildCollectionItem(col),
                    )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumnSwitch(BuildContext context, SettingsManager settings) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final prefColumns = settings.collectionsListColumns;
    final activeColumns = prefColumns == 0 ? (isLandscape ? 2 : 1) : prefColumns;
    final l10n = LocalizationService();

    return WidgetUtils.tooltip(
      message: l10n.translate('toggle_layout'),
      child: IconButton(
        icon: Icon(
          activeColumns == 2 ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
          color: AppConstants.textColor,
        ),
        onPressed: () {
          settings.setCollectionsListColumns(activeColumns == 1 ? 2 : 1);
        },
      ),
    );
  }

  Widget _buildCollectionItem(SeriesCollection col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.title,
                      style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${col.publisherName} | ${col.editionName}',
                      style: TextStyle(color: AppConstants.textMutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${col.countMain} Vols',
                  style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniBadge(col.format),
              _buildMiniBadge(col.medium),
              _buildMiniBadge(col.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: AppConstants.textMutedColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
