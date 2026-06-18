import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';


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
}

class CoverOnlyGridItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;

  const CoverOnlyGridItem({super.key, required this.series, this.heroTagPrefix});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppConstants.secondaryBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: EntryListLayoutHelper.buildCoverImage(
        series: series,
        heroTagPrefix: heroTagPrefix,
        width: double.infinity,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}

class CompactGridItem extends StatelessWidget {
  final Series series;
  final String? heroTagPrefix;
  final String displayTitle;

  const CompactGridItem({
    super.key,
    required this.series,
    this.heroTagPrefix,
    required this.displayTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Card(
            color: AppConstants.secondaryBackground,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.zero,
            child: EntryListLayoutHelper.buildCoverImage(
              series: series,
              heroTagPrefix: heroTagPrefix,
              width: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: SizedBox(
            height: 18,
            child: Text(
              displayTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                    fontSize: 12,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
