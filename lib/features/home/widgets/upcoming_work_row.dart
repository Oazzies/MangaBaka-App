import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/models/series_work.dart';

/// Day section header for [UpcomingWorksScreen].
class UpcomingDayHeader extends StatelessWidget {
  final DateTime? day;
  final bool first;
  final LocalizationService l10n;

  const UpcomingDayHeader({
    super.key,
    required this.day,
    required this.first,
    required this.l10n,
  });

  String _relative(DateTime d) {
    final now = DateTime.now();
    final days = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return l10n.translate('upcoming_today');
    if (days == 1) return l10n.translate('upcoming_tomorrow');
    return DateFormat('EEEE').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final isToday =
        d != null && _relative(d) == l10n.translate('upcoming_today');
    return Padding(
      padding: EdgeInsets.fromLTRB(0, first ? 8 : 20, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            d == null
                ? l10n.translate('upcoming_date_tba').toUpperCase()
                : DateFormat('d MMM').format(d).toUpperCase(),
            style: AppTypography.display(
              color: isToday ? context.colors.accent : context.colors.text,
              fontSize: d == null ? 14 : 20,
            ),
          ),
          if (d != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _relative(d).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoLabel(
                  color: context.colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single release row in [UpcomingWorksScreen].
class UpcomingWorkRow extends StatelessWidget {
  final SeriesWork work;
  final String? cover;
  final bool inLibrary;
  final VoidCallback? onTap;

  const UpcomingWorkRow({
    super.key,
    required this.work,
    required this.cover,
    required this.inLibrary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = work.seriesTitle ?? work.subTitle;
    final volume = work.sequenceString.isNotEmpty
        ? 'Vol. ${work.sequenceString}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 76,
                    child: cover == null
                        ? ColoredBox(
                            color: context.colors.surfaceRaised,
                            child: Icon(
                              Icons.book_outlined,
                              size: 20,
                              color: context.colors.textMuted,
                            ),
                          )
                        : WidgetUtils.networkImage(
                            url: cover!,
                            fit: BoxFit.cover,
                            memCacheWidth: 160,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (volume.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          volume,
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (inLibrary) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.accent.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LocalizationService()
                                .translate('upcoming_in_library')
                                .toUpperCase(),
                            style: AppTypography.monoLabel(
                              color: context.colors.accent,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
