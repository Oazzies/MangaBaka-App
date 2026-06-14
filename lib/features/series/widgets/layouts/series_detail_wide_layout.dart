import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/features/series/widgets/series_metadata_chips.dart';
import 'package:mangabaka_app/features/series/widgets/series_action_bar.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_genres_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_skeleton.dart';

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

  static const double _hPadding = 40.0;
  static const double _sidebarWidth = 300.0;
  static const double _columnGap = 48.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isDataLoaded
          ? _buildContent()
          : Padding(
              key: const ValueKey('wide_skeleton'),
              padding: const EdgeInsets.symmetric(horizontal: _hPadding),
              child: const SeriesDetailSkeleton(isWide: true),
            ),
    );
  }

  Widget _buildContent() {
    return Column(
      key: const ValueKey('wide_full_layout'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar and divider stay in a fixed position across every tab so
        // switching tabs never shifts the chrome sideways.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hPadding),
          child: SeriesSegmentedControl(
            selectedTab: selectedTab,
            onTabChanged: onTabChanged,
            horizontalPadding: 0,
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: AppConstants.tertiaryBackground,
        ),
        if (selectedTab == 'Info') _buildInfoBody(),
        const SizedBox(height: 24),
        buildTabContent(_hPadding, isWide: true, wideRightPaddingOnly: false),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic);
  }

  /// Two balanced columns that both start on the same line below the divider:
  /// left holds the at-a-glance facts and actions, right holds the longer-form
  /// ratings, description and genres.
  Widget _buildInfoBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 32, _hPadding, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _sidebarWidth,
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
                if (entry != null) ...[
                  const SizedBox(height: 24),
                  SeriesActionBar(
                    series: series,
                    entry: entry,
                    l10n: l10n,
                    onStateChanged: onStateChanged,
                    onRatingChanged: onRatingChanged,
                    onUpdateChapter: onUpdateChapter,
                    onUpdateVolume: onUpdateVolume,
                  ),
                ],
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic),
          ),
          const SizedBox(width: _columnGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExternalRatingsSection(series: series),
                if (series.description.isNotEmpty) ...[
                  SeriesSectionHeader(title: l10n.translate('description')),
                  DescriptionSection(description: series.description),
                  const SizedBox(height: 32),
                ],
                SeriesGenresSection(series: series, l10n: l10n),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 80.ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }
}
