import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';

class SeriesWorksTab extends StatelessWidget {
  final List<SeriesWork>? works;
  final double horizontalPadding;

  const SeriesWorksTab({
    super.key, 
    this.works,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (works == null) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    if (works!.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.translate('no_works_available'))));
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          final isGrid = settings.worksListStyle.isGrid;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SeriesSectionHeader(
                      title: l10n.translate('tab_works'),
                      bottomPadding: 0,
                    ),
                  ),
                  _buildListStyleSwitch(context, settings),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (isGrid) {
                    return _buildGridView(context, constraints.maxWidth);
                  } else {
                    return _buildListView(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListStyleSwitch(BuildContext context, SettingsManager settings) {
    final isGrid = settings.worksListStyle.isGrid;
    final l10n = LocalizationService();

    return WidgetUtils.tooltip(
      message: l10n.translate('toggle_layout'),
      child: IconButton(
        icon: Icon(
          isGrid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
          color: AppConstants.textColor,
        ),
        onPressed: () {
          settings.setWorksListStyle(isGrid ? AppListStyle.comfortable : AppListStyle.compactGrid);
        },
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: works!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildListItem(context, works![index]),
    );
  }

  Widget _buildGridView(BuildContext context, double maxWidth) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 4 : 2;
    final spacing = 12.0;
    final itemWidth = (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: 16,
      children: works!.map((w) => _buildGridItem(context, w, itemWidth)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, SeriesWork w) {
    final l10n = LocalizationService();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            height: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: WidgetUtils.networkImage(
                url: w.imageUrl ?? '',
                fit: BoxFit.cover,
                memCacheWidth: 150,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.subTitle.isNotEmpty ? w.subTitle : l10n.translate('volume_title').replaceAll('{index}', w.sequenceString),
                        style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (w.priceString != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          w.priceString!,
                          style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translate('release_date').replaceAll('{date}', w.releaseDate),
                  style: TextStyle(color: AppConstants.textMutedColor, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 14, color: AppConstants.textMutedColor),
                    const SizedBox(width: 4),
                    Text(l10n.translate('pages_count').replaceAll('{count}', w.pages.toString()), style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.label_outline, size: 14, color: AppConstants.textMutedColor),
                    const SizedBox(width: 4),
                    Text(w.countType, style: TextStyle(color: AppConstants.textMutedColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, SeriesWork w, double width) {
    final l10n = LocalizationService();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.7,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WidgetUtils.networkImage(
                  url: w.imageUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            w.subTitle.isNotEmpty ? w.subTitle : l10n.translate('volume_title').replaceAll('{index}', w.sequenceString),
            style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (w.priceString != null) ...[
            const SizedBox(height: 2),
            Text(
              w.priceString!,
              style: TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
