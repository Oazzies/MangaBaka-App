import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_layouts.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item_list_layouts.dart';

/// Top-left ranking badge shown on grid cards in [EntryListItem].
class EntryRankingBadge extends StatelessWidget {
  final int ranking;

  const EntryRankingBadge({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.accent,
          // Matches the 8px grid card it sits in the corner of.
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          '$ranking',
          style: AppTypography.display(
            color: context.colors.onAccent,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Thin progress bar shown below/inside [EntryListItem] rows.
class EntryProgressBar extends StatelessWidget {
  final Series series;
  final LibraryEntry entry;
  final int? optimisticProgress;

  const EntryProgressBar({
    super.key,
    required this.series,
    required this.entry,
    this.optimisticProgress,
  });

  @override
  Widget build(BuildContext context) {
    final totalChapters = int.tryParse(series.totalChapters) ?? 0;
    if (totalChapters <= 0) return const SizedBox.shrink();

    final progress = optimisticProgress ?? entry.progressChapter ?? 0;
    final percentage = (progress / totalChapters).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: percentage,
        backgroundColor: context.colors.surfaceRaised,
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
        minHeight: 3,
      ),
    );
  }
}

/// Switches between grid and list layout widgets for [EntryListItem].
class EntryListItemContent extends StatelessWidget {
  final Series series;
  final AppListStyle style;
  final LocalizationService l10n;
  final String displayTitle;
  final LibraryEntry? entry;
  final String? heroTagPrefix;
  final int? optimisticProgress;
  final bool hovered;

  const EntryListItemContent({
    super.key,
    required this.series,
    required this.style,
    required this.l10n,
    required this.displayTitle,
    required this.entry,
    this.heroTagPrefix,
    this.optimisticProgress,
    this.hovered = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppListStyle.coverOnlyGrid:
        return CoverOnlyGridItem(
          series: series,
          heroTagPrefix: heroTagPrefix,
          entry: entry,
          progressOverride: optimisticProgress,
          hovered: hovered,
        );
      case AppListStyle.compactGrid:
        return CompactGridItem(
          series: series,
          heroTagPrefix: heroTagPrefix,
          displayTitle: displayTitle,
          hovered: hovered,
          entry: entry,
          progressOverride: optimisticProgress,
        );
      case AppListStyle.minimalList:
        return MinimalListItem(
          series: series,
          heroTagPrefix: heroTagPrefix,
          displayTitle: displayTitle,
        );
      case AppListStyle.compact:
        return CompactListItem(
          series: series,
          heroTagPrefix: heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
      case AppListStyle.comfortable:
        return ComfortableListItem(
          series: series,
          heroTagPrefix: heroTagPrefix,
          displayTitle: displayTitle,
          l10n: l10n,
        );
    }
  }
}
