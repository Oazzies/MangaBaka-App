import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/chips/type_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/status_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/licensed_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/volume_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/chapters_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/date_range_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/has_anime_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/rating_chip.dart';
import 'package:mangabaka_app/features/series/widgets/chips/content_rating_chip.dart';
import 'package:mangabaka_app/features/series/widgets/id_chip.dart';

import 'package:mangabaka_app/core/settings/settings_manager.dart';

class SeriesMetadataChips extends StatelessWidget {
  final Series series;
  final LibraryEntry? entry;
  final bool isVertical;
  final VoidCallback? onUpdateChapter;
  final VoidCallback? onUpdateVolume;
  final VoidCallback? onUpdateRating;

  const SeriesMetadataChips({
    super.key,
    required this.series,
    this.entry,
    this.isVertical = false,
    this.onUpdateChapter,
    this.onUpdateVolume,
    this.onUpdateRating,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final List<Widget> children = [
          if (series.type.isNotEmpty) TypeChip(type: series.type),
          if (series.status.isNotEmpty) StatusChip(status: series.status),
          if (series.isLicensed == 'true') const LicensedChip(),
          if (series.finalVolume.isNotEmpty && series.finalVolume != 'null' && entry == null)
            VolumeChip(
              volume: series.finalVolume,
              progress: entry?.progressVolume,
              inLibrary: entry != null,
              onTap: onUpdateVolume,
            ),
          if (series.totalChapters.isNotEmpty && series.totalChapters != 'null' && entry == null)
            ChaptersChip(
              chapters: series.totalChapters,
              progress: entry?.progressChapter,
              inLibrary: entry != null,
              onTap: onUpdateChapter,
            ),
          if ((series.published?['start_date']?.toString().isNotEmpty ?? false) ||
              (series.published?['end_date']?.toString().isNotEmpty ?? false))
            DateRangeChip(
              start: series.published?['start_date']?.toString() ?? '',
              end: series.published?['end_date']?.toString() ?? '',
            ),
          if (series.hasAnime == 'true') const HasAnimeChip(),
          if ((entry?.rating ?? 0) > 0)
            RatingChip(
              sources: (series.source?.values.toList() ?? []),
              entry: entry,
              onTap: onUpdateRating,
            ),
          if (['suggestive', 'erotica', 'pornographic'].contains(series.contentRating.toLowerCase()))
            ContentRatingChip(rating: series.contentRating),
          IdChip(id: series.id),
        ];

        if (isVertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: c,
            )).toList(),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        );
      },
    );
  }
}

