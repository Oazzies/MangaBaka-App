import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(
              series: series,
              heroTagPrefix: heroTagPrefix,
              width: 48,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, right: 110),
                child: Text(
                  displayTitle,
                  style: AppTypography.sans(
                    color: context.colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 84,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(
              series: series,
              heroTagPrefix: heroTagPrefix,
              width: 60,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 110,
                  top: 10,
                  bottom: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayTitle,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('type_${series.type.toLowerCase()}')} · ${l10n.translate('status_${series.status.toLowerCase()}')} · ${series.year}',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 13,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            EntryListLayoutHelper.buildCoverImage(
              series: series,
              heroTagPrefix: heroTagPrefix,
              width: 72,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 115,
                  top: 10,
                  bottom: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayTitle,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('type_${series.type.toLowerCase()}')} · ${l10n.translate('status_${series.status.toLowerCase()}')} · ${series.year}',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ratingValue > 0) ...[
                      const SizedBox(height: 6),
                      MbRatingStars(rating: ratingValue, fontSize: 12),
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
