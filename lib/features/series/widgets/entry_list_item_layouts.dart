import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/progress_update_dialog.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';


class EntryListLayoutHelper {
  static Widget buildCoverImage({
    required Series series,
    required String? heroTagPrefix,
    required double width,
    double? height,
    BorderRadiusGeometry borderRadius = const BorderRadius.horizontal(left: Radius.circular(8)),
  }) {
    final heroTag = heroTagPrefix != null 
        ? '${heroTagPrefix}_${series.id}' 
        : 'series_cover_${series.id}';

    return Hero(
      tag: heroTag,
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final isBlurred = SettingsManager().blurredContentRatings.contains(series.contentRating.toLowerCase());
          return ClipRRect(
            borderRadius: borderRadius,
            child: WidgetUtils.networkImage(
              url: series.coverUrl,
              width: width,
              height: height ?? double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              blurred: isBlurred,
            ),
          );
        },
      ),
    );
  }

  static Widget buildPlaceholder(double width, double? height) {
    return Container(
      width: width,
      height: height ?? double.infinity,
      color: AppConstants.secondaryBackground,
      child: Icon(
        Icons.broken_image,
        color: AppConstants.textMutedColor,
        size: width > 50 ? 40 : 24,
      ),
    );
  }

  static Widget buildTopOverlays({
    required BuildContext context,
    required double cardWidth,
    required Series series,
    required LibraryEntry? entry,
    required int? progressOverride,
    required SettingsManager settings,
    required LocalizationService l10n,
  }) {
    if (entry == null) return const SizedBox.shrink();

    final showProgress = settings.showLibraryProgress;
    final showRemaining = settings.showRemainingProgress;

    if (!showProgress && !showRemaining) return const SizedBox.shrink();

    final isChapter = settings.libraryProgressType == LibraryProgressType.chapters;
    final total = isChapter
        ? (int.tryParse(series.totalChapters) ?? 0)
        : (int.tryParse(series.finalVolume) ?? 0);
    final progress = progressOverride ?? (isChapter ? entry.progressChapter : entry.progressVolume) ?? 0;

    int remaining = 0;
    if (total > 0) {
      remaining = total - progress;
    }

    final hasRemainingBadge = showRemaining && total > 0 && remaining > 0;
    final hasProgressBadge = showProgress;

    if (!hasRemainingBadge && !hasProgressBadge) return const SizedBox.shrink();

    // Shared badge decoration: solid dark pill with a subtle drop shadow.
    // Using a const BoxDecoration avoids repeated allocation across rebuilds.
    BoxDecoration badgeDecoration() => const BoxDecoration(
      color: Color(0xFF121214),
      borderRadius: BorderRadius.all(Radius.circular(20)),
      boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 2))],
    );

    Widget buildProgressContent() {
      final prefix = isChapter ? 'Ch. ' : 'Vol. ';
      return Text(
        '$prefix$progress${total > 0 ? '/$total' : ''}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }

    Widget buildRemainingContent() {
      return Text(
        remaining.toString(),
        style: TextStyle(
          color: AppConstants.warningColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }

    void openUpdateDialog() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProgressUpdateDialog(
            initialValue: progress,
            title: isChapter ? l10n.translate('update_chapters') : l10n.translate('update_volumes'),
            maxValue: isChapter ? series.totalChapters : series.finalVolume,
            onUpdate: (value) {
              final libraryService = getIt<LibraryService>();
              if (isChapter) {
                libraryService.updateLibraryEntryProgress(series.id, progressChapter: value);
              } else {
                libraryService.updateLibraryEntryProgress(series.id, progressVolume: value);
              }
            },
          ),
        ),
      );
    }

    // Determine if we should combine them based on card width
    final shouldCombine = hasRemainingBadge && hasProgressBadge && cardWidth < 145;

    if (shouldCombine) {
      return Positioned(
        top: 8,
        left: 8,
        right: 8,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openUpdateDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: badgeDecoration(),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildRemainingContent(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 1,
                        height: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    buildProgressContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (hasRemainingBadge)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: badgeDecoration(),
              child: buildRemainingContent(),
            ),
          ),
        if (hasProgressBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openUpdateDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: badgeDecoration(),
                  child: buildProgressContent(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CoverOnlyGridItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final LibraryEntry? entry;
  final int? progressOverride;

  const CoverOnlyGridItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    this.entry,
    this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.secondaryBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final l10n = LocalizationService();
          final settings = SettingsManager();

          return Stack(
            fit: StackFit.expand,
            children: [
              EntryListLayoutHelper.buildCoverImage(
                series: series,
                heroTagPrefix: heroTagPrefix,
                width: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
              EntryListLayoutHelper.buildTopOverlays(
                context: context,
                cardWidth: constraints.maxWidth,
                series: series,
                entry: entry,
                progressOverride: progressOverride,
                settings: settings,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}

class CompactGridItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final String displayTitle;
  final LibraryEntry? entry;
  final int? progressOverride;

  const CompactGridItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    required this.displayTitle,
    this.entry,
    this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 0.65,
          child: Card(
            color: AppConstants.secondaryBackground,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final l10n = LocalizationService();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    EntryListLayoutHelper.buildCoverImage(
                      series: series,
                      heroTagPrefix: heroTagPrefix,
                      width: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                    EntryListLayoutHelper.buildTopOverlays(
                      context: context,
                      cardWidth: constraints.maxWidth,
                      series: series,
                      entry: entry,
                      progressOverride: progressOverride,
                      settings: settings,
                      l10n: l10n,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              displayTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                    fontSize: 12,
                  ),
              maxLines: settings.compactGridTitleRows,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
