import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Opens [series]' detail page from anywhere on desktop.
void openSeriesDetail(BuildContext context, Series series, {String? heroTag}) {
  SeriesHoverPreviewController.instance.hide();
  Navigator.of(context).push(
    AppTransitions.slideUp(
      SeriesDetailScreen(series: series, heroTagPrefix: heroTag),
    ),
  );
}

/// A cover with its title beneath, for rails and grids.
///
/// On hover the cover lifts and gains an accent ring, and the detail page is
/// prefetched — by the time the click lands it usually has its data.
class DesktopCoverCard extends StatefulWidget {
  final Series series;
  final double width;
  final String? caption;
  final String heroTag;
  final VoidCallback? onTap;

  /// False shows the cover alone, for dense strips of thumbnails.
  final bool showTitle;

  const DesktopCoverCard({
    super.key,
    required this.series,
    this.width = 150,
    this.caption,
    this.heroTag = 'desktop',
    this.onTap,
    this.showTitle = true,
  });

  @override
  State<DesktopCoverCard> createState() => _DesktopCoverCardState();
}

class _DesktopCoverCardState extends State<DesktopCoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final rating = double.tryParse(series.rating) ?? 0;
    final title = series.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );

    return SeriesHoverPreview(
      series: series,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          getIt<SeriesService>().fetchSeries(series.id);
        },
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            SeriesHoverPreviewController.instance.hide();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              openSeriesDetail(context, series, heroTag: widget.heroTag);
            }
          },
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSlide(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  offset: _hovered ? const Offset(0, -0.02) : Offset.zero,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.emphasized,
                    width: widget.width,
                    height: widget.width * 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hovered
                            ? context.colors.accent
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: _hovered ? context.colors.softShadow : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: WidgetUtils.networkImage(
                        url: series.coverUrl,
                        blurred: WidgetUtils.isRatingBlurred(
                          series.contentRating,
                        ),
                        width: widget.width,
                        height: widget.width * 1.5,
                        memCacheWidth: (widget.width * 2).round(),
                      ),
                    ),
                  ),
                ),
                if (widget.showTitle) ...[
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: _hovered
                          ? context.colors.accent
                          : context.colors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (widget.caption != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ] else if (rating > 0) ...[
                    const SizedBox(height: 4),
                    MbRatingStars(rating: rating, outOf: 100, fontSize: 11),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
