import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/models/series_link.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/features/series/widgets/series_grouped_tags.dart';
import 'package:bakahyou/utils/widget_utils.dart';

class SeriesDetailsGrid extends StatelessWidget {
  final Series series;
  final List<SeriesLink>? enrichedLinks;
  final bool isWide;
  final LocalizationService l10n;

  const SeriesDetailsGrid({
    super.key,
    required this.series,
    this.enrichedLinks,
    this.isWide = false,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final metadataService = getIt<MetadataService>();

    final content = [
      // Genres moved to SeriesDetailScreen
      SeriesGroupedTags(series: series, l10n: l10n),
      if (series.authors.isNotEmpty) ...[
        WidgetUtils.chipWrap(
          l10n.translate('authors'),
          series.authors,
          color: AppConstants.secondaryBackground,
        ),
        const SizedBox(height: 12),
      ],
      if (series.artists.isNotEmpty) ...[
        WidgetUtils.chipWrap(
          l10n.translate('artists'),
          series.artists,
          color: AppConstants.secondaryBackground,
        ),
        const SizedBox(height: 12),
      ],
      if (series.publishers.isNotEmpty) ...[
        WidgetUtils.chipWrap(
          l10n.translate('publishers'),
          series.publishers,
          color: AppConstants.secondaryBackground,
        ),
        const SizedBox(height: 12),
      ],
      if (enrichedLinks != null || series.links.isNotEmpty) ...[
        const SizedBox(height: 24),
        WidgetUtils.linkList(enrichedLinks ?? series.links),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
