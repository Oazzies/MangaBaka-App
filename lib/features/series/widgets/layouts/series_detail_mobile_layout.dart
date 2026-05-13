import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/features/series/widgets/series_metadata_chips.dart';
import 'package:mangabaka_app/features/series/widgets/series_action_bar.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_genres_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_skeleton.dart';

import 'package:mangabaka_app/features/series/widgets/external_ratings_section.dart';

class SeriesDetailMobileLayout extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;
  final LocalizationService l10n;
  final bool isDataLoaded;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final Function(String) onStateChanged;
  final Function(int) onRatingChanged;
  final VoidCallback onUpdateChapter;
  final VoidCallback onUpdateVolume;
  final VoidCallback onUpdateRating;
  final Widget Function(double hPadding) buildTabContent;

  const SeriesDetailMobileLayout({
    super.key,
    required this.series,
    required this.entry,
    required this.l10n,
    required this.isDataLoaded,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onStateChanged,
    required this.onRatingChanged,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.onUpdateRating,
    required this.buildTabContent,
  });

  @override
  Widget build(BuildContext context) {
    const hPadding = 16.0;
    
    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isDataLoaded 
        ? Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                key: const ValueKey('full_layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: hPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SeriesMetadataChips(
                          series: series, 
                          entry: entry,
                          onUpdateChapter: onUpdateChapter,
                          onUpdateVolume: onUpdateVolume,
                          onUpdateRating: onUpdateRating,
                        ),
                        const SizedBox(height: 16),
                        SeriesActionBar(
                          entry: entry, 
                          l10n: l10n,
                          onStateChanged: onStateChanged,
                          onRatingChanged: onRatingChanged,
                        ),
                        const SizedBox(height: 20),
                        ExternalRatingsSection(series: series),
                        if (series.description.isNotEmpty) ...[
                          SeriesSectionHeader(title: l10n.translate('description')),
                          DescriptionSection(description: series.description),
                          const SizedBox(height: 20),
                        ],
                        SeriesGenresSection(series: series, l10n: l10n),
                        SeriesSegmentedControl(
                          selectedTab: selectedTab,
                          onTabChanged: onTabChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildTabContent(hPadding),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic)
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPadding),
            child: Column(
              key: const ValueKey('skeleton_layout'),
              children: [
                const SeriesDetailSkeleton(),
                const SizedBox(height: 400),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
