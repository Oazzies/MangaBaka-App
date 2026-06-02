import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
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
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SeriesDetailHeader extends StatelessWidget {
  final Series series;
  final int? progressChapter;
  final int? progressVolume;
  final bool inLibrary;

  const SeriesDetailHeader({
    super.key,
    required this.series,
    this.progressChapter,
    this.progressVolume,
    this.inLibrary = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final preferredTitle = series.getDisplayTitle(settings.defaultTitleLanguage);
    
    // Determine which other titles to show
    final otherTitles = <String>[];
    if (series.title.isNotEmpty && series.title != preferredTitle) {
      otherTitles.add(series.title);
    }
    if (series.nativeTitle.isNotEmpty && 
        series.nativeTitle != preferredTitle && 
        !otherTitles.contains(series.nativeTitle)) {
      otherTitles.add(series.nativeTitle);
    }
    if (series.romanizedTitle.isNotEmpty && 
        series.romanizedTitle != preferredTitle && 
        !otherTitles.contains(series.romanizedTitle)) {
      otherTitles.add(series.romanizedTitle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (series.coverUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WidgetUtils.networkImage(
              url: series.coverUrl,
              height: 160,
              width: 110,
              fit: BoxFit.cover,
              memCacheWidth: 220,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _HoverableTitleText(
                      text: preferredTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                      onTap: () => Clipboard.setData(ClipboardData(text: preferredTitle)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IdChip(id: series.id),
                ],
              ),
              ...otherTitles.map((t) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: _HoverableTitleText(
                  text: t,
                  style: t == otherTitles.first 
                    ? Theme.of(context).textTheme.bodyMedium
                    : Theme.of(context).textTheme.bodySmall,
                  onTap: () => Clipboard.setData(ClipboardData(text: t)),
                ),
              )),

              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TypeChip(type: series.type),
                  StatusChip(status: series.status),
                  if (series.isLicensed == 'true') LicensedChip(),
                  if (series.finalVolume.isNotEmpty &&
                      series.finalVolume != 'null')
                    VolumeChip(
                      volume: series.finalVolume,
                      progress: progressVolume,
                      inLibrary: inLibrary,
                    ),
                  if (series.totalChapters.isNotEmpty &&
                      series.totalChapters != 'null')
                    ChaptersChip(
                      chapters: series.totalChapters,
                      progress: progressChapter,
                      inLibrary: inLibrary,
                    ),
                  if ((series.published?['start_date']?.toString().isNotEmpty ??
                          false) ||
                      (series.published?['end_date']?.toString().isNotEmpty ??
                          false))
                    DateRangeChip(
                      start: series.published?['start_date']?.toString() ?? '',
                      end: series.published?['end_date']?.toString() ?? '',
                    ),
                  if (series.hasAnime == 'true') HasAnimeChip(),
                  RatingChip(sources: (series.source?.values.toList() ?? [])),
                  if ([
                    'suggestive',
                    'erotica',
                    'pornographic',
                  ].contains(series.contentRating.toLowerCase()))
                    ContentRatingChip(rating: series.contentRating),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A text widget that underlines on hover to indicate it is clickable/copyable.
class _HoverableTitleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final VoidCallback onTap;

  const _HoverableTitleText({
    required this.text,
    this.style,
    this.overflow,
    required this.onTap,
  });

  @override
  State<_HoverableTitleText> createState() => _HoverableTitleTextState();
}

class _HoverableTitleTextState extends State<_HoverableTitleText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(
              decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
              decorationColor: (baseStyle.color ?? AppConstants.textColor).withValues(alpha: 0.6),
            ),
            overflow: widget.overflow,
          ),
        ),
      ),
    );
  }
}
