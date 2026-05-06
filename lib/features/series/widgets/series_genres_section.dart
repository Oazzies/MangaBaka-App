import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

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
        _buildSectionHeader(l10n.translate('genres')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: series.genres
              .map((g) => ChipBase(
                    label: Text(metadataService.getGenreLabel(g)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.textColor, letterSpacing: 0.5)),
    );
  }
}
