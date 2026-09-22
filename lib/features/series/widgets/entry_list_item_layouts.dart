import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_progress_overlay.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class EntryListLayoutHelper {
  static Widget buildCoverImage({
    required Series series,
    required String? heroTagPrefix,
    required double width,
    double? height,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    ),
  }) {
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_${series.id}'
        : 'series_cover_${series.id}';

    return Hero(
      tag: heroTag,
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final isBlurred = SettingsManager().blurredContentRatings.contains(
            series.contentRating.toLowerCase(),
          );
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
    return Builder(
      builder: (context) => Container(
        width: width,
        height: height ?? double.infinity,
        color: context.colors.surfaceRaised,
        child: Icon(
          Icons.broken_image,
          color: context.colors.textMuted,
          size: width > 50 ? 40 : 24,
        ),
      ),
    );
  }

  /// The progress badges laid over a grid cover.
  ///
  /// Kept as a delegate so the grid layouts below read the same as they did;
  /// the badges themselves are [EntryProgressOverlay].
  static Widget buildTopOverlays({
    required BuildContext context,
    required double cardWidth,
    required Series series,
    required LibraryEntry? entry,
    required int? progressOverride,
    required SettingsManager settings,
    required LocalizationService l10n,
  }) {
    return EntryProgressOverlay(
      series: series,
      entry: entry,
      cardWidth: cardWidth,
      progressOverride: progressOverride,
      settings: settings,
      l10n: l10n,
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
      color: context.colors.surface,
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
            color: context.colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                color: context.colors.text,
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
