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

  /// Height reserved for the title (up to 2 lines), below the 9px gap
  /// after the cover.
  static double _titleAreaHeight(double textScale) => 40 * textScale;

  /// Height reserved for the caption/rating row, below its own gap.
  static double _metaAreaHeight(double textScale) => 20 * textScale;

  /// Gap before the title, and before the caption/rating row beneath it.
  static const double _titleGap = 9;
  static const double _metaGap = 4;

  /// Room to reserve below the cover image for the title and the
  /// caption/rating row beneath it, for a caller computing a fixed row
  /// height (e.g. [DesktopCarousel]'s `height:`).
  ///
  /// This must stay in lockstep with the fixed-size boxes the title and
  /// caption/rating are wrapped in below — real font/DPI/text-scale metrics
  /// are too variable to predict from a formula (a guessed pixel budget
  /// repeatedly proved too small in practice and overflowed the row), so
  /// instead each text element is capped to a guaranteed size and clips
  /// rather than grows. That makes this value exactly correct by
  /// construction instead of an estimate.
  static double textAreaHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return _titleGap +
        _titleAreaHeight(scale) +
        _metaGap +
        _metaAreaHeight(scale);
  }

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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

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
                  const SizedBox(height: DesktopCoverCard._titleGap),
                  // Capped to a fixed, guaranteed size (see textAreaHeight)
                  // rather than sized to the text's own natural height —
                  // real font/DPI/text-scale metrics vary too much to
                  // reliably predict, so a title that would need more room
                  // clips instead of overflowing the card.
                  SizedBox(
                    height: DesktopCoverCard._titleAreaHeight(textScale),
                    child: ClipRect(
                      child: Text(
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
                    ),
                  ),
                  const SizedBox(height: DesktopCoverCard._metaGap),
                  SizedBox(
                    height: DesktopCoverCard._metaAreaHeight(textScale),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: widget.caption != null
                            ? Text(
                                widget.caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sans(
                                  color: context.colors.textMuted,
                                  fontSize: 12,
                                ),
                              )
                            : rating > 0
                            ? MbRatingStars(
                                rating: rating,
                                outOf: 100,
                                fontSize: 11,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
