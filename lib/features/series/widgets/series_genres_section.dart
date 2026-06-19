import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

class SeriesGenresSection extends StatelessWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGenresSection({super.key, required this.series, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (series.genres.isEmpty) return const SizedBox.shrink();
    final metadataService = getIt<MetadataService>();
    final detailState = SeriesDetailScreen.of(context);
    final isSelecting = detailState?.drawerFilters != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesSectionHeader(title: l10n.translate('genres')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < series.genres.length; i++)
              Builder(
                builder: (context) {
                  final genre = series.genres[i];
                  final isSelected = detailState?.drawerFilters?.genre.contains(genre) ?? false;
                  return ChipBase(
                    label: Text(
                      metadataService.getGenreLabel(genre),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: isSelected ? Colors.white : AppConstants.textColor,
                      ),
                    ),
                    borderRadius: AppConstants.pillRadius,
                    backgroundColor: isSelected
                        ? AppConstants.accentColor
                        : AppConstants.secondaryBackground,
                    borderColor: isSelected
                        ? AppConstants.accentColor
                        : AppConstants.borderColor,
                    onTap: () {
                      if (isSelecting) {
                        detailState?.handleGenreLongPress(genre);
                      } else {
                        detailState?.handleGenreTap(genre);
                      }
                    },
                    onLongPress: () => detailState?.handleGenreLongPress(genre),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
