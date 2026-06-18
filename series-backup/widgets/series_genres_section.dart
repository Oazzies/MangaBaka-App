import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';

class SeriesGenresSection extends StatelessWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGenresSection({super.key, required this.series, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (series.genres.isEmpty) return const SizedBox.shrink();
    final metadataService = getIt<MetadataService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesSectionHeader(title: l10n.translate('genres')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < series.genres.length; i++)
              ChipBase(
                label: Text(metadataService.getGenreLabel(series.genres[i])),
                borderRadius: AppConstants.pillRadius,
                backgroundColor: AppConstants.secondaryBackground,
                borderColor: AppConstants.borderColor,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: AppConstants.textColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
