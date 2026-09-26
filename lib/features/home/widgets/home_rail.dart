import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// One horizontally scrolling discovery rail on the Home feed: a display-caps
/// section header over a row of cover cards.
class HomeRail extends StatelessWidget {
  final String title;
  final List<Series> series;
  final bool loading;
  final double coverWidth;

  /// Optional trailing arrow on the section header (e.g. "see the full list").
  final VoidCallback? onViewAll;

  /// When false the section header is omitted — for callers (like the Trending
  /// section) that render their own header and controls above the row.
  final bool showHeader;

  /// Placeholder count shown while [loading] is true.
  static const int _skeletonCount = 5;

  const HomeRail({
    super.key,
    required this.title,
    required this.series,
    this.loading = false,
    this.coverWidth = 118,
    this.onViewAll,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    // A rail that resolved to nothing is dropped rather than shown empty.
    if (!loading && series.isEmpty) return const SizedBox.shrink();

    final itemCount = loading ? _skeletonCount : series.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) MbSectionHeader(title: title, onAction: onViewAll),
        SizedBox(
          height: coverWidth * 1.5 + 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (loading) {
                return _RailSkeleton(width: coverWidth);
              }
              return MbEntrance(
                index: i,
                child: _RailCard(series: series[i], width: coverWidth),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  final Series series;
  final double width;

  const _RailCard({required this.series, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MbTappable(
        pressedScale: 0.95,
        onTap: () => Navigator.of(context).push(
          AppTransitions.slideUp(
            SeriesDetailScreen(series: series, heroTagPrefix: 'home_rail'),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MbCover(url: series.coverUrl, width: width, memCacheWidth: 300),
            const SizedBox(height: 8),
            Text(
              series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  final double width;

  const _RailSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surfaceRaised,
      highlightColor: context.colors.surface,
      period: const Duration(milliseconds: 1400),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width,
              height: width * 1.5,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: width * 0.8,
              height: 12,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
