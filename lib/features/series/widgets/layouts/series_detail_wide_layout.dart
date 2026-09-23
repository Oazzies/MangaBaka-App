import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_fab.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_genres_section.dart';
import 'package:mangabaka_app/features/series/widgets/series_segmented_control.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_skeleton.dart';
import 'package:mangabaka_app/features/series/widgets/series_my_list_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_information_card.dart';
import 'package:mangabaka_app/features/series/widgets/external_ratings_section.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesDetailWideLayout extends StatelessWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final LocalizationService l10n;
  final bool isDataLoaded;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final Function(String) onStateChanged;
  final Function(int) onRatingChanged;
  final bool isAdding;
  final VoidCallback onAdd;
  final VoidCallback onUpdateChapter;
  final VoidCallback onUpdateVolume;
  final VoidCallback onUpdateRating;
  final Function(String)? onAuthorTap;
  final Function(String)? onPublisherTap;

  /// Optional content for a right-hand rail, sitting in the same scrolling row
  /// as the left sidebar. Used by the Discovery Queue to put its controls
  /// opposite the Information card.
  final Widget? rightRail;

  final Widget Function(
    double hPadding, {
    bool isWide,
    bool wideRightPaddingOnly,
  })
  buildTabContent;

  const SeriesDetailWideLayout({
    super.key,
    required this.series,
    required this.title,
    required this.entry,
    required this.l10n,
    required this.isDataLoaded,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onStateChanged,
    required this.onRatingChanged,
    required this.isAdding,
    required this.onAdd,
    required this.onUpdateChapter,
    required this.onUpdateVolume,
    required this.onUpdateRating,
    this.onAuthorTap,
    this.onPublisherTap,
    this.rightRail,
    required this.buildTabContent,
  });

  static const double _hPadding = 40.0;
  static const double _sidebarWidth = 272.0;
  static const double _columnGap = 44.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isDataLoaded
          ? _buildContent(context)
          : Padding(
              key: const ValueKey('wide_skeleton'),
              padding: const EdgeInsets.symmetric(horizontal: _hPadding),
              child: const SeriesDetailSkeleton(isWide: true),
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      key: const ValueKey('wide_full_layout'),
      padding: const EdgeInsets.fromLTRB(_hPadding, 0, _hPadding, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar: overlapping cover + My List + Information.
          SizedBox(
            width: _sidebarWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry != null) ...[
                  SeriesMyListCard(
                    series: series,
                    entry: entry!,
                    l10n: l10n,
                    onStateChanged: onStateChanged,
                    onUpdateChapter: onUpdateChapter,
                    onUpdateVolume: onUpdateVolume,
                    onUpdateRating: onUpdateRating,
                  ),
                  const SizedBox(height: 18),
                ],
                SeriesInformationCard(
                  series: series,
                  l10n: l10n,
                  onAuthorTap: onAuthorTap,
                  onPublisherTap: onPublisherTap,
                ),
                // Only a signed-in user can add, and only what is not yet in
                // their library — the same gate the phone's FAB applies.
                if (entry == null &&
                    getIt<ProfileAuthService>().isLoggedIn) ...[
                  const SizedBox(height: 18),
                  SeriesAddToLibraryButton(isAdding: isAdding, onAdd: onAdd),
                ],
              ],
            ),
          ),
          const SizedBox(width: _columnGap),
          // Main column: title block + tabs + content.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeriesSegmentedControl(
                  selectedTab: selectedTab,
                  onTabChanged: onTabChanged,
                  horizontalPadding: 0,
                ),
                Divider(height: 1, thickness: 1, color: context.colors.border),
                if (selectedTab == 'Info') _buildInfoPanel(),
                const SizedBox(height: 32),
                buildTabContent(0, isWide: true, wideRightPaddingOnly: false),
              ],
            ),
          ),
          if (rightRail != null) ...[
            const SizedBox(width: _columnGap),
            SizedBox(width: _sidebarWidth, child: rightRail),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
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
      ),
    );
  }
}
