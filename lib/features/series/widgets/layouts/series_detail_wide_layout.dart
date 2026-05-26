import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';

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
    const hPadding = 40.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: hPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTabContent(hPadding, isWide: true, wideRightPaddingOnly: true),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: hPadding),
                child: SeriesSegmentedControl(
                  selectedTab: selectedTab,
                  onTabChanged: onTabChanged,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
