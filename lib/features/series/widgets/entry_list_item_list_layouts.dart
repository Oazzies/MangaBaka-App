import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';

class MinimalListItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final String displayTitle;

  const MinimalListItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    required this.displayTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(series: series, heroTagPrefix: heroTagPrefix, width: 48),
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
}

class CompactListItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final String displayTitle;
  final LocalizationService l10n;

  const CompactListItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    required this.displayTitle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 84,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(series: series, heroTagPrefix: heroTagPrefix, width: 60),
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
                    const SizedBox(height: 4),
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
}

class ComfortableListItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final String displayTitle;
  final LocalizationService l10n;

  const ComfortableListItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    required this.displayTitle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ratingValue = double.tryParse(series.rating) ?? 0.0;

    return Card(
      color: AppConstants.secondaryBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(series: series, heroTagPrefix: heroTagPrefix, width: 72),
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
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('type_${series.type.toLowerCase()}')} • ${l10n.translate('status_${series.status.toLowerCase()}')} • ${series.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.accentColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ratingValue > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppConstants.textMutedColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingValue.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppConstants.textMutedColor.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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
