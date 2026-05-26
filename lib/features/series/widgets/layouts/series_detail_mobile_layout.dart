import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';

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
    this.entry,
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

    return Container(
      decoration: BoxDecoration(
          color: AppConstants.primaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.largeRadius),
            topRight: Radius.circular(AppConstants.largeRadius),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          buildTabContent(hPadding),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: SeriesSegmentedControl(
              selectedTab: selectedTab,
              onTabChanged: onTabChanged,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
