import 'package:flutter/material.dart';
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
import 'package:mangabaka_app/features/series/widgets/series_hero_cover.dart';

import 'package:mangabaka_app/features/series/widgets/external_ratings_section.dart';

class SeriesDetailWideLayout extends StatelessWidget {
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
  final Widget Function(double hPadding, {bool isWide, bool wideRightPaddingOnly}) buildTabContent;

  const SeriesDetailWideLayout({
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
    const hPadding = 40.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: hPadding),
          child: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDataLoaded)
                  SeriesMetadataChips(
                    series: series, 
                    entry: entry, 
                    isVertical: false,
                    onUpdateChapter: onUpdateChapter,
                    onUpdateVolume: onUpdateVolume,
                    onUpdateRating: onUpdateRating,
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: AnimatedSwitcher(
            duration: 600.ms,
            child: isDataLoaded 
              ? Column(
                  key: const ValueKey('wide_full_layout'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            const SizedBox(height: 24),
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
                    buildTabContent(hPadding, isWide: true, wideRightPaddingOnly: true),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic)
              : Padding(
                  padding: const EdgeInsets.only(right: hPadding),
                  child: const SeriesDetailSkeleton(key: ValueKey('wide_skeleton'), isWide: true),
                ),
          ),
        ),
      ],
    );
  }
}
