import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_card.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_cover_fan.dart';

/// Lays stack cards out in as many columns of at most [maxTileWidth] as fit,
/// each row exactly as tall as a card at that width.
///
/// The row height is worked out at layout time from the tile width, so a
/// window resize relayouts the grid without rebuilding it.
class StackGridDelegate extends SliverGridDelegate {
  final double maxTileWidth;
  final double spacing;
  final double runSpacing;

  /// Height of the text under each card's covers.
  final double textHeight;

  const StackGridDelegate({
    required this.textHeight,
    this.maxTileWidth = 200,
    this.spacing = 14,
    this.runSpacing = 22,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final extent = constraints.crossAxisExtent;
    final columns = math.max(
      1,
      ((extent + spacing) / (maxTileWidth + spacing)).ceil(),
    );
    final tileWidth = (extent - spacing * (columns - 1)) / columns;
    final tileHeight = StackCoverFan.heightFor(tileWidth) + textHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: tileHeight + runSpacing,
      crossAxisStride: tileWidth + spacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(StackGridDelegate oldDelegate) =>
      oldDelegate.maxTileWidth != maxTileWidth ||
      oldDelegate.spacing != spacing ||
      oldDelegate.runSpacing != runSpacing ||
      oldDelegate.textHeight != textHeight;
}

/// A sliver grid of stack cards, with skeleton tiles while [loading] and
/// nothing yet loaded.
class SliverStackGrid extends StatelessWidget {
  final List<StackSummary> stacks;
  final bool loading;
  final bool showVisibility;

  const SliverStackGrid({
    super.key,
    required this.stacks,
    this.loading = false,
    this.showVisibility = false,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final skeleton = loading && stacks.isEmpty;
    return SliverGrid(
      gridDelegate: StackGridDelegate(
        textHeight: StackCard.textHeight(context),
        maxTileWidth: desktop ? 230 : 190,
        spacing: desktop ? 18 : 14,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => skeleton
            ? const StackCardSkeleton()
            : MbEntrance(
                index: i,
                child: StackCard(
                  stack: stacks[i],
                  showVisibility: showVisibility,
                ),
              ),
        childCount: skeleton ? 6 : stacks.length,
      ),
    );
  }
}

/// A titled horizontal row of stacks: the desktop carousel with paging
/// buttons on desktop, a swipe rail elsewhere. Drops out when it resolved to
/// nothing.
class StacksRail extends StatelessWidget {
  final String title;
  final List<StackSummary> stacks;
  final bool loading;
  final VoidCallback? onViewAll;
  final bool showVisibility;
  final Widget? trailing;

  /// Card width on a phone.
  final double cardWidth;

  /// Side inset of the phone rail; zero when the parent already pads it.
  final double gutter;

  const StacksRail({
    super.key,
    required this.title,
    required this.stacks,
    this.loading = false,
    this.onViewAll,
    this.showVisibility = false,
    this.trailing,
    this.cardWidth = 168,
    this.gutter = AppConstants.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && stacks.isEmpty) return const SizedBox.shrink();
    final skeleton = loading && stacks.isEmpty;
    final count = skeleton ? 5 : stacks.length;
    Widget item(BuildContext context, int i) => skeleton
        ? const StackCardSkeleton()
        : StackCard(stack: stacks[i], showVisibility: showVisibility);

    if (DesktopLayout.isActive(context)) {
      return DesktopCarousel(
        title: title,
        itemCount: count,
        itemWidth: 220,
        itemHeight: (w) => StackCard.heightFor(context, w),
        onViewAll: onViewAll,
        trailing: trailing,
        itemBuilder: item,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbSectionHeader(
          title: title,
          onAction: onViewAll,
          trailing: trailing,
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
        ),
        SizedBox(
          height: StackCard.heightFor(context, cardWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => SizedBox(
              width: cardWidth,
              child: MbEntrance(index: i, child: item(context, i)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// A grey placeholder in a card's shape, while stacks load.
class StackCardSkeleton extends StatelessWidget {
  const StackCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StackCoverFan(covers: []),
        const SizedBox(height: 12),
        bar(0.85, 13),
        const SizedBox(height: 8),
        bar(0.55, 10),
      ],
    );
  }
}
