import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/series_grouped_tags.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final animeStart = series.anime?['start']?.toString();
    final animeStop = series.anime?['end']?.toString();

    final content = [
      if (animeStart != null && animeStart.trim().isNotEmpty)
        WidgetUtils.chipWrap(
          l10n.translate('anime_start'),
          animeStart.split('/').map((e) => e.trim()).toList(),
          color: AppConstants.secondaryBackground,
        ),
      if (animeStop != null && animeStop.trim().isNotEmpty)
        WidgetUtils.chipWrap(
          l10n.translate('anime_stop'),
          animeStop.split('/').map((e) => e.trim()).toList(),
          color: AppConstants.secondaryBackground,
        ),
      // Genres moved to SeriesDetailScreen
      SeriesGroupedTags(series: series, l10n: l10n),
      if (series.authors.isNotEmpty)
        WidgetUtils.chipWrap(
          l10n.translate('authors'),
          series.authors,
          color: AppConstants.secondaryBackground,
        ),
      if (series.artists.isNotEmpty)
        WidgetUtils.chipWrap(
          l10n.translate('artists'),
          series.artists,
          color: AppConstants.secondaryBackground,
        ),
      if (series.publishers.isNotEmpty)
        WidgetUtils.chipWrap(
          l10n.translate('publishers'),
          series.publishers,
          color: AppConstants.secondaryBackground,
        ),
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
