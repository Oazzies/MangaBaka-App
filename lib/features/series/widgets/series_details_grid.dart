import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_grouped_tags.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesDetailsGrid extends StatelessWidget {
  final Series series;
  final List<SeriesLink>? enrichedLinks;
  final bool isWide;
  final LocalizationService l10n;
  final double horizontalPadding;

  const SeriesDetailsGrid({
    super.key,
    required this.series,
    this.enrichedLinks,
    this.isWide = false,
    required this.l10n,
    this.horizontalPadding = 16.0,
  });

  Widget _buildAnimeContainer(BuildContext context) {
    final animeStart = series.anime?['start']?.toString();
    final animeStop = series.anime?['end']?.toString();

    final hasStart = animeStart != null && animeStart.trim().isNotEmpty;
    final hasStop = animeStop != null && animeStop.trim().isNotEmpty;

    if (!hasStart && !hasStop) return const SizedBox.shrink();

    final children = <Widget>[
      if (hasStart) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('anime_start').toUpperCase(),
                style: AppTypography.monoLabel(
                  color: context.colors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                animeStart,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
      if (hasStart && hasStop)
        Divider(height: 1, thickness: 1, color: context.colors.border),
      if (hasStop) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('anime_stop').toUpperCase(),
                style: AppTypography.monoLabel(
                  color: context.colors.textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                animeStop,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: MbCard(
        label: l10n.translate('anime_adaptation'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = [
      _buildAnimeContainer(context),
      // Genres moved to SeriesDetailScreen
      SeriesGroupedTags(series: series, l10n: l10n),
      if (enrichedLinks != null || series.links.isNotEmpty) ...[
        const SizedBox(height: 8),
        WidgetUtils.linkList(enrichedLinks ?? series.links),
      ],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }
}
