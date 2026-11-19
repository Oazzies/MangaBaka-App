import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';

class SnapshotListItem extends StatelessWidget {
  final Series series;

  final String heroScope;

  static const double coverWidth = 120;

  const SnapshotListItem({
    super.key,
    required this.series,
    this.heroScope = 'snapshot',
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final displayTitle = series.getDisplayTitle(
          SettingsManager().defaultTitleLanguage,
        );
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeriesDetailScreen(
                  series: series,
                  heroTagPrefix: heroScope,
                ),
              ),
            );
          },
          child: SizedBox(
            width: coverWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MbCover(
                  url: series.coverUrl,
                  width: coverWidth,
                  blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                  memCacheWidth: 240,
                  heroTag: '${heroScope}_${series.id}',
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 16,
                  child: Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
