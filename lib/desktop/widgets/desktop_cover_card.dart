import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/desktop/widgets/series_hover_preview.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

void openSeriesDetail(BuildContext context, Series series, {String? heroTag}) {
  SeriesHoverPreviewController.instance.hide();
  Navigator.of(context).push(
    AppTransitions.slideUp(
      SeriesDetailScreen(series: series, heroTagPrefix: heroTag),
    ),
  );
}

class DesktopCoverCard extends StatefulWidget {
  final Series series;

  final double? width;

  final String? caption;
  final String heroTag;
  final VoidCallback? onTap;
  final SeriesPrefetch prefetch;

  final bool showTitle;

  final bool showRating;

  const DesktopCoverCard({
    super.key,
    required this.series,
    required this.prefetch,
    this.width,
    this.caption,
    this.heroTag = 'desktop',
    this.onTap,
    this.showTitle = true,
    this.showRating = true,
  });

  static double _titleAreaHeight(double textScale) => 40 * textScale;

  static double _metaAreaHeight(double textScale) => 20 * textScale;

  static const double _titleGap = 9;
  static const double _metaGap = 4;

  /// Fixed, not a fraction of cover height, so [DesktopCarousel.liftRoom] can stay a small constant.
  static const double hoverLift = 3.0;

  /// Fixed so a window-following slot never re-decodes; wide enough for the widest stretched slot.
  static const double fillDecodeWidth = 256;

  /// Must stay in lockstep with the fixed-size title and caption boxes below: font, DPI and
  /// text-scale metrics are too variable to predict, so each box caps and clips its text.
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
          widget.prefetch(series.id);
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
          child: _sized(
            // Fractional-scale pixel rounding can overflow by under a pixel; ClipRect absorbs it.
            ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sized at layout, so a resize never rebuilds the card. Never animate the size:
                  // covers then tween on every resize frame and overflow their slot.
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.emphasized,
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
                          memCacheWidth: WidgetUtils.decodeWidth(
                            context,
                            widget.width ?? DesktopCoverCard.fillDecodeWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showTitle) ...[
                    const SizedBox(height: DesktopCoverCard._titleGap),
                    // Fixed size, not natural height: see textAreaHeight.
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
                              : rating > 0 && widget.showRating
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
      ),
    );
  }

  Widget _sized(Widget child) {
    final width = widget.width;
    return width == null ? child : SizedBox(width: width, child: child);
  }
}
