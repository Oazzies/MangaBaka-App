import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_list_layouts.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/settings/settings_enums.dart';

class EntryListItem extends StatelessWidget {
  final Series series;
  final int? ranking;
  final bool isLibrary;
  final String? heroTagPrefix;

  const EntryListItem({
    super.key, 
    required this.series, 
    this.ranking, 
    this.isLibrary = false,
    this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService(),
        SettingsManager(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        final displayTitle = series.getDisplayTitle(settings.defaultTitleLanguage);
        final style = settings.separateListStyles 
            ? (isLibrary ? settings.libraryListStyle : settings.browseListStyle)
            : settings.currentListStyle;

        return Stack(
          children: [
            _buildContent(context, style, l10n, displayTitle),

            if (ranking != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.warningColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '$ranking',
                    style: TextStyle(
                      color: AppConstants.primaryBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AppListStyle style, LocalizationService l10n, String displayTitle) {
    switch (style) {
      case AppListStyle.coverOnlyGrid:
        return CoverOnlyGridItem(series: series, heroTagPrefix: heroTagPrefix);
      case AppListStyle.compactGrid:
        return CompactGridItem(series: series, heroTagPrefix: heroTagPrefix, displayTitle: displayTitle);
      case AppListStyle.minimalList:
        return MinimalListItem(series: series, heroTagPrefix: heroTagPrefix, displayTitle: displayTitle);
      case AppListStyle.compact:
        return CompactListItem(series: series, heroTagPrefix: heroTagPrefix, displayTitle: displayTitle, l10n: l10n);
      case AppListStyle.comfortable:
        return ComfortableListItem(series: series, heroTagPrefix: heroTagPrefix, displayTitle: displayTitle, l10n: l10n);
    }
  }
}
