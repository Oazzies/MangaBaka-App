import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/home/screens/upcoming_works_screen.dart';
import 'package:mangabaka_app/features/home/services/upcoming_loader.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// The next few releases as a Home rail, each card dated, with an arrow into
/// the full [UpcomingWorksScreen]. Dropped when nothing is coming up.
class HomeUpcomingRail extends StatelessWidget {
  final UpcomingData data;
  final double coverWidth;

  /// How many releases the rail shows before deferring to the full screen.
  static const int _maxCards = 12;

  const HomeUpcomingRail({super.key, required this.data, this.coverWidth = 118});

  @override
  Widget build(BuildContext context) {
    final works = [
      for (final w in data.works)
        if (data.coverFor(w) != null) w,
    ].take(_maxCards).toList();
    if (works.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbSectionHeader(
          title: LocalizationService().translate('upcoming_releases'),
          onAction: () => UpcomingWorksScreen.open(context, initial: data),
        ),
        SizedBox(
          height: coverWidth * 1.5 + 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            itemCount: works.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => MbEntrance(
              index: i,
              child: _UpcomingCard(
                work: works[i],
                cover: data.coverFor(works[i])!,
                width: coverWidth,
                // The card is the series; the arrow on the header is the list.
                onTap: () => works[i].seriesId == null
                    ? UpcomingWorksScreen.open(context, initial: data)
                    : openUpcomingSeries(context, works[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final SeriesWork work;
  final String cover;
  final double width;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.work,
    required this.cover,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = UpcomingData.dayOf(work);
    final title = work.seriesTitle ?? work.subTitle;
    // "6 OCT - VOL. 3": the volume rides with the date, not the title.
    final when = [
      if (day != null) DateFormat('d MMM').format(day).toUpperCase(),
      if (work.sequenceString.isNotEmpty) 'VOL. ${work.sequenceString}',
    ].join(' - ');

    return SizedBox(
      width: width,
      child: MbTappable(
        pressedScale: 0.95,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: width,
                height: width * 1.5,
                child: WidgetUtils.networkImage(
                  url: cover,
                  width: width,
                  height: width * 1.5,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (when.isNotEmpty)
              Text(
                when,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoLabel(
                  color: context.colors.accent,
                  fontSize: 11,
                ),
              ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
