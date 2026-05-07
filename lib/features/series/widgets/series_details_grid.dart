import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/models/series_link.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/widgets/series_grouped_tags.dart';
import 'package:bakahyou/utils/widget_utils.dart';

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
    final content = [
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
