import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';

class DesktopUpcomingOverlay extends StatelessWidget {
  final Widget feed;
  final double railWidth;
  final bool open;
  final bool built;
  final Widget rail;

  const DesktopUpcomingOverlay({
    super.key,
    required this.feed,
    required this.railWidth,
    required this.open,
    required this.built,
    required this.rail,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: feed),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: railWidth,
          child: IgnorePointer(
            ignoring: !open,
            child: AnimatedSlide(
              offset: Offset(open ? 0 : 1, 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.background,
                  border: Border(
                    left: BorderSide(color: context.colors.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FixedColors.dim.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: built ? rail : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DesktopHomeRail extends StatelessWidget {
  final String title;
  final List<Series> series;
  final bool loading;
  final VoidCallback? onViewAll;
  final SeriesPrefetch prefetch;

  const DesktopHomeRail({
    super.key,
    required this.title,
    required this.series,
    required this.loading,
    required this.prefetch,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && series.isEmpty) return const SizedBox.shrink();

    final textArea = DesktopCoverCard.textAreaHeight(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        DesktopTokens.pagePadding,
        DesktopTokens.sectionGap,
      ),
      child: DesktopCarousel(
        title: title,
        loading: loading && series.isEmpty,
        onViewAll: onViewAll,
        itemCount: series.length,
        itemWidth: 156,
        stretch: true,
        itemHeight: (width) => width * 1.5 + textArea,
        itemBuilder: (context, i) => DesktopCoverCard(
          series: series[i],
          prefetch: prefetch,
          heroTag: 'home_${title}_$i',
          showRating: false,
        ),
      ),
    );
  }
}
