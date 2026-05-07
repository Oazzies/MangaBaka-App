import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';


class EntryListItem extends StatelessWidget {
  final Series series;
  final int? ranking;
  final bool isLibrary;

  const EntryListItem({super.key, required this.series, this.ranking, this.isLibrary = false});

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
        return _buildCoverOnlyGridItem(context);
      case AppListStyle.compactGrid:
        return _buildCompactGridItem(context, displayTitle);
      case AppListStyle.minimalList:
        return _buildMinimalListItem(context, l10n, displayTitle);
      case AppListStyle.compact:
        return _buildCompactListItem(context, l10n, displayTitle);
      case AppListStyle.comfortable:
      default:
        return _buildComfortableListItem(context, l10n, displayTitle);
    }
  }


  Widget _buildCoverImage({
    required double width,
    double? height,
    BorderRadiusGeometry borderRadius = const BorderRadius.horizontal(left: Radius.circular(8)),
  }) {
    return Hero(
      tag: 'series_cover_${series.id}',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: series.coverUrl.isNotEmpty
            ? Image.network(
                series.coverUrl,
                width: width,
                height: height ?? double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 300,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(width, height);
                },
              )
            : _buildPlaceholder(width, height),
      ),
    );
  }

  Widget _buildPlaceholder(double width, double? height) {
    return Container(
      width: width,
      height: height ?? double.infinity,
      color: AppConstants.secondaryBackground,
      child: Icon(
        Icons.broken_image,
        color: AppConstants.textMutedColor,
        size: width > 50 ? 40 : 24,
      ),
    );
  }



  Widget _buildCoverOnlyGridItem(BuildContext context) {
    return Card(
      color: AppConstants.secondaryBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: _buildCoverImage(
        width: double.infinity,
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  Widget _buildCompactGridItem(BuildContext context, String displayTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Card(
            color: AppConstants.secondaryBackground,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.zero,
            child: _buildCoverImage(
              width: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: SizedBox(
            height: 18, // Fixed height for title area
            child: Text(
              displayTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                    fontSize: 12,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMinimalListItem(BuildContext context, LocalizationService l10n, String displayTitle) {

    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _buildCoverImage(width: 48),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                        fontSize: 16,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactListItem(BuildContext context, LocalizationService l10n, String displayTitle) {

    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 84,
        child: Row(
          children: [
            _buildCoverImage(width: 60),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColor,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${l10n.translate('type_${series.type.toLowerCase()}')} - ${l10n.translate('status_${series.status.toLowerCase()}')} - ${series.year}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textMutedColor,
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComfortableListItem(BuildContext context, LocalizationService l10n, String displayTitle) {

    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            _buildCoverImage(width: 80),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColor,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${l10n.translate('type_${series.type.toLowerCase()}')} - ${l10n.translate('status_${series.status.toLowerCase()}')} - ${series.year}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textMutedColor,
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: series.genres.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = series.genres[index];
                          final genreLabel = getIt<MetadataService>().getGenreLabel(genre);
                          return Chip(
                            label: Text(
                              genreLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppConstants.textColor,
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            side: BorderSide(
                              color: AppConstants.textMutedColor,
                              width: 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
