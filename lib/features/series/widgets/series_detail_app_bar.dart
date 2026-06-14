import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero_cover.dart';
import 'package:mangabaka_app/features/series/widgets/series_hero.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Banner hero for the series detail page: a full-bleed blurred cover that fades
/// into the page background, with the cover artwork and serif title block
/// floating at its base, plus a glass "Back" pill and (portrait only) transparent
/// share / delete icons. Landscape shows the back pill only. The remaining
/// content (tabs, cards, synopsis) lives below.
class SeriesDetailAppBar extends StatefulWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final bool isWide;
  final bool showCover;
  final double horizontalPadding;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Function(String) onCopy;

  const SeriesDetailAppBar({
    super.key,
    required this.series,
    required this.title,
    this.entry,
    required this.isWide,
    this.showCover = true,
    this.horizontalPadding = 16.0,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  State<SeriesDetailAppBar> createState() => _SeriesDetailAppBarState();
}

class _SeriesDetailAppBarState extends State<SeriesDetailAppBar> {
  bool _transitionComplete = false;
  bool _listenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _listenerAdded = true;
      final route = ModalRoute.of(context);
      if (route != null) {
        final animation = route.animation;
        if (animation != null && !animation.isCompleted) {
          animation.addStatusListener(_onStatus);
        } else {
          _transitionComplete = true;
        }
      } else {
        _transitionComplete = true;
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _transitionComplete = true);
      ModalRoute.of(context)?.animation?.removeStatusListener(_onStatus);
    }
  }

  @override
  void dispose() {
    // Safe to call even if already removed
    ModalRoute.of(context)?.animation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate the margin needed to center the app bar contents on screens wider than 1400px
    final double horizontalMargin = math.max(0.0, (screenWidth - 1400) / 2);

    final double expandedHeight = widget.isWide
        ? (isLandscape ? 330 : 380)
        : (isLandscape ? 220 : 300);
    final double coverHeight = widget.isWide
        ? (isLandscape ? 190 : 230)
        : (isLandscape ? 140 : 172);
    final double coverWidth = coverHeight * 0.7;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final double offset = constraints.scrollOffset;
        final double fadeStart = expandedHeight * 0.45;
        final double fadeEnd = expandedHeight - kToolbarHeight;
        final double titleOpacity =
            ((offset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);

        return SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          backgroundColor: AppConstants.primaryBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          // Always reserve space for the "Back" text pill.
          leadingWidth: (widget.isWide ? 150 : 120) + horizontalMargin,
          leading: Padding(
            padding: EdgeInsets.only(
              left: (widget.isWide ? 40.0 : 16.0) + horizontalMargin, 
              top: 6, 
              bottom: 6,
            ),
            child: _GlassControl(
              onTap: widget.onBack,
              tooltip: LocalizationService().translate('go_back'),
              icon: Icons.arrow_back,
              // Design: "Back" label in both portrait and landscape.
              label: LocalizationService().translate('back'),
              showBg: titleOpacity < 0.5,
            ).animate().fadeIn(duration: 400.ms),
          ),
          // Landscape: no banner icons — clean behind the back pill.
          // Portrait: transparent circle share + delete (if in library).
          actions: widget.isWide
              ? [
                  Padding(
                    padding: EdgeInsets.only(right: horizontalMargin + 16),
                    child: const SizedBox(width: 16),
                  )
                ]
              : [
                  _SubbarIcon(
                    onTap: widget.onShare,
                    tooltip: LocalizationService().translate('share_series'),
                    icon: Icons.share_outlined,
                    showBg: titleOpacity < 0.5,
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                  if (widget.entry != null) ...[
                    const SizedBox(width: 8),
                    _SubbarIcon(
                      onTap: widget.onDelete,
                      tooltip: LocalizationService().translate('delete_from_library'),
                      icon: Icons.delete_outline,
                      showBg: titleOpacity < 0.5,
                    ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
                  ],
                  Padding(
                    padding: EdgeInsets.only(right: horizontalMargin + 8),
                    child: const SizedBox(width: 8),
                  ),
                ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsetsDirectional.only(
              start: (widget.isWide ? 166 : 136) + horizontalMargin,
              bottom: 16,
              end: (widget.isWide
                      ? 16.0
                      : widget.entry != null
                          ? 104.0
                          : 60.0) +
                  horizontalMargin,
            ),
            centerTitle: false,
            title: IgnorePointer(
              ignoring: titleOpacity == 0,
              child: Opacity(
                opacity: titleOpacity,
                child: Text(
                  widget.title,
                  style: AppTypography.serif(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            background: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppConstants.tertiaryBackground),
                  // Defer the expensive blur until after the route transition
                  // completes to avoid GPU contention during the slide animation.
                  if (widget.series.coverUrl.isNotEmpty)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      opacity: _transitionComplete ? 1.0 : 0.0,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                        child: seriesBannerImage(widget.series, memCacheWidth: widget.isWide ? 1200 : 800),
                      ),
                    ),
                  Container(
                    color: AppConstants.primaryBackground.withValues(alpha: 0.2),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _HatchPainter(
                        color: AppConstants.textColor.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  // Fade into the page background toward the bottom.
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryBackground.withValues(alpha: 0.0),
                          AppConstants.primaryBackground.withValues(alpha: 0.4),
                          AppConstants.primaryBackground.withValues(alpha: 0.92),
                          AppConstants.primaryBackground,
                        ],
                        stops: const [0.25, 0.55, 0.85, 1.0],
                      ),
                    ),
                  ),
                  // Cover + serif title block floating at the base.
                  if (widget.showCover)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SeriesHeroCover(
                                  series: widget.series,
                                  height: coverHeight,
                                  width: coverWidth,
                                ),
                                SizedBox(width: widget.isWide ? 22 : 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: SeriesTitleBlock(
                                      series: widget.series,
                                      title: widget.title,
                                      isWide: widget.isWide,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A frosted-glass control (back pill / icon button) that floats on the banner.
class _GlassControl extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  final IconData icon;
  final String? label;
  final bool showBg;

  const _GlassControl({
    required this.onTap,
    required this.tooltip,
    required this.icon,
    this.label,
    this.showBg = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final child = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: showBg ? 10 : 0,
          sigmaY: showBg ? 10 : 0,
        ),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: label != null ? 14 : 0),
          width: label != null ? null : 40,
          decoration: BoxDecoration(
            color: showBg
                ? AppConstants.secondaryBackground.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppConstants.textColor),
              if (label != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label!,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: AppConstants.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return WidgetUtils.tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: child),
      ),
    );
  }
}

/// Frosted-glass circular icon button for portrait banner right-side controls.
class _SubbarIcon extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  final IconData icon;
  final bool showBg;

  const _SubbarIcon({
    required this.onTap,
    required this.tooltip,
    required this.icon,
    this.showBg = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final child = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: showBg ? 10 : 0,
          sigmaY: showBg ? 10 : 0,
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: showBg
                ? AppConstants.secondaryBackground.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: radius,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: AppConstants.textColor),
          ),
        ),
      ),
    );

    return WidgetUtils.tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: child),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  final Color color;
  _HatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 14.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) => old.color != color;
}
