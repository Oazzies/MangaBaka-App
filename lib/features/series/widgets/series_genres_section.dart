import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

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
              .map((g) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppConstants.tertiaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.borderColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      metadataService.getGenreLabel(g),
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
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
