import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class HomeRail extends StatelessWidget {
  final String title;
  final List<Series> series;
  final bool loading;
  final double coverWidth;

  final VoidCallback? onViewAll;

  final bool showHeader;

  /// For rails outside Home, whose titles would otherwise collide with same-named Home rails.
  final String? heroScopeId;

  /// Unique per rail, so a series in two rails never shares a Hero tag.
  String get heroScope =>
      heroScopeId ?? 'home_${title.isEmpty ? 'trending' : title}';

  static const int _skeletonCount = 5;

  static const double defaultCoverWidth = 118;

  static double heightFor(double coverWidth) => coverWidth * 1.5 + 42;

  const HomeRail({
    super.key,
    required this.title,
    required this.series,
    this.loading = false,
    this.coverWidth = defaultCoverWidth,
    this.onViewAll,
    this.showHeader = true,
    this.heroScopeId,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && series.isEmpty) return const SizedBox.shrink();

    final skeleton = series.isEmpty;
    final itemCount = skeleton ? _skeletonCount : series.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) MbSectionHeader(title: title, onAction: onViewAll),
        SizedBox(
          height: heightFor(coverWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (skeleton) return _RailSkeleton(width: coverWidth);
              return MbEntrance(
                index: i,
                child: _RailCard(
                  series: series[i],
                  width: coverWidth,
                  heroScope: heroScope,
                ),
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
  final String heroScope;

  const _RailCard({
    required this.series,
    required this.width,
    required this.heroScope,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MbTappable(
        pressedScale: 0.95,
        onTap: () => Navigator.of(context).push(
          AppTransitions.slideUp(
            SeriesDetailScreen(series: series, heroTagPrefix: heroScope),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MbCover(
              url: series.coverUrl,
              width: width,
              memCacheWidth: 300,
              heroTag: '${heroScope}_${series.id}',
              blurred: WidgetUtils.isRatingBlurred(series.contentRating),
            ),
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
