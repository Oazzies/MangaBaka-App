import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Where the items of a carousel row fall at a given row width.
///
/// Worked out at layout time — by the row itself, by the list's item
/// extents, and by paging — never at build time, so resizing the window
/// re-lays the row out without rebuilding a single item.
class CarouselGeometry {
  /// Whole items visible at once.
  final int count;

  /// Width of each item.
  final double itemWidth;

  /// Width the row occupies — narrower than the space available when items
  /// aren't stretched, so the row ends on an item boundary instead of
  /// cutting its last visible item in half.
  final double rowWidth;

  const CarouselGeometry._(this.count, this.itemWidth, this.rowWidth);

  /// Items of [targetWidth] spaced by [spacing] across [available].
  ///
  /// With [stretch] the items grow so that a whole number of them exactly
  /// fills [available]: the first item's left edge and the last visible
  /// item's right edge line up with whatever sits above and below the row.
  factory CarouselGeometry.resolve(
    double available, {
    required double targetWidth,
    required double spacing,
    required bool stretch,
  }) {
    final step = targetWidth + spacing;
    // The epsilon: an available width that fits n items exactly can land a
    // hair under n in floating point, and floor() would drop one.
    final count = ((available + spacing) / step + 1e-6).floor().clamp(
      1,
      1 << 30,
    );
    if (stretch) {
      return CarouselGeometry._(
        count,
        (available - (count - 1) * spacing) / count,
        available,
      );
    }
    return CarouselGeometry._(
      count,
      targetWidth,
      (count * step - spacing).clamp(0.0, available),
    );
  }
}

/// A titled horizontal row with previous/next buttons.
///
/// A mouse wheel scrolls vertically, so a phone-style swipe rail is close to
/// unusable on desktop: the only ways along it were a trackpad or dragging the
/// scrollbar. The arrow buttons page by whole items.
///
/// Items are given their slot — [CarouselGeometry.itemWidth] wide,
/// [itemHeight] of that tall — and must fill it rather than size themselves.
class DesktopCarousel extends StatefulWidget {
  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// The width an item aims for; see [stretch].
  final double itemWidth;

  /// Grow items so a whole number of them fills the row exactly, rather than
  /// narrowing the row to a whole number of [itemWidth] items.
  final bool stretch;

  /// An item's height for a given item width (a cover plus its caption).
  final double Function(double itemWidth) itemHeight;

  final double spacing;
  final Widget? trailing;
  final VoidCallback? onViewAll;
  final bool loading;

  /// Called when the row is scrolled near its end, for paging in more.
  final VoidCallback? onNearEnd;

  const DesktopCarousel({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.itemHeight,
    this.stretch = false,
    this.spacing = 18,
    this.trailing,
    this.onViewAll,
    this.loading = false,
    this.onNearEnd,
  });

  /// Room reserved above each item, inside the row's clipped viewport, so a
  /// hovered cover's lift has somewhere to go without its top edge being
  /// clipped off. Sized to [DesktopCoverCard.hoverLift] plus a little slack
  /// for the hover shadow's own soft bleed above the card.
  static const double liftRoom = DesktopCoverCard.hoverLift + 3;

  @override
  State<DesktopCarousel> createState() => _DesktopCarouselState();
}

class _DesktopCarouselState extends State<DesktopCarousel> {
  final ScrollController _scroll = ScrollController();
  bool _canBack = false;
  bool _canForward = true;
  double? _lastViewport;

  int get _count => widget.loading ? 8 : widget.itemCount;

  CarouselGeometry _geometry(double width) => CarouselGeometry.resolve(
    width,
    targetWidth: widget.itemWidth,
    spacing: widget.spacing,
    stretch: widget.stretch,
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onMetrics() {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    if (viewport != _lastViewport) {
      _lastViewport = viewport;
      // Stretched items change width with the row, which moves every item
      // boundary under a scroll position that hasn't moved: a row scrolled
      // in would sit mid-item until realigned.
      if (widget.stretch) _realign();
    }
    _update();
  }

  void _realign() {
    if (!_scroll.hasClients || !mounted) return;
    final p = _scroll.position;
    if (p.pixels == 0) return;
    final g = _geometry(p.viewportDimension);
    final step = g.itemWidth + widget.spacing;
    final target = ((p.pixels / step).round() * step).clamp(
      0.0,
      p.maxScrollExtent,
    );
    if ((target - p.pixels).abs() > 0.5) _scroll.jumpTo(target);
  }

  void _update() {
    if (!_scroll.hasClients || !mounted) return;
    final p = _scroll.position;
    final back = p.pixels > 4;
    final forward = p.pixels < p.maxScrollExtent - 4;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
    final g = _geometry(p.viewportDimension);
    if (p.pixels > p.maxScrollExtent - g.itemWidth * 3) {
      widget.onNearEnd?.call();
    }
  }

  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final g = _geometry(p.viewportDimension);
    final step = g.itemWidth + widget.spacing;
    // Page by whole items so the row always lands on an item boundary, from
    // the boundary at-or-before the current position — rounding to the
    // nearest would sometimes snap forward past a clamped partial last page.
    final aligned = (p.pixels / step).floor() * step;
    final target = (aligned + direction * g.count * step).clamp(
      0.0,
      p.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final count = _count;
    final spacing = widget.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionTitle(
          title: widget.title,
          // Tighter than the default 14px — this title sits right above
          // its own row rather than a block of unrelated content. Safe to
          // shrink because the row's hover-lift reserve lives inside the row.
          padding: const EdgeInsets.only(bottom: 4),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 12),
              ],
              if (widget.onViewAll != null) ...[
                DesktopPillButton(
                  label: l10n.translate('view_all'),
                  onPressed: widget.onViewAll,
                ),
                const SizedBox(width: 8),
              ],
              DesktopIconButton(
                icon: Icons.chevron_left_rounded,
                filled: true,
                tooltip: l10n.translate('back'),
                onPressed: _canBack ? () => _page(-1) : null,
              ),
              const SizedBox(width: 6),
              DesktopIconButton(
                icon: Icons.chevron_right_rounded,
                filled: true,
                tooltip: l10n.translate('onboarding_next'),
                onPressed: _canForward ? () => _page(1) : null,
              ),
            ],
          ),
        ),
        _CarouselRow(
          geometry: _geometry,
          itemHeight: widget.itemHeight,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _onMetrics());
              return false;
            },
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              // Clip.none let cards paint outside this row's own width — on
              // the profile page, scrolled-in covers spilled over the sidebar.
              clipBehavior: Clip.hardEdge,
              itemCount: count,
              // Each item's extent includes the gap after it (the last has
              // none), resolved from the row's width during layout.
              itemExtentBuilder: (index, dimensions) {
                if (index >= count) return null;
                final width = _geometry(
                  dimensions.viewportMainAxisExtent,
                ).itemWidth;
                return index == count - 1 ? width : width + spacing;
              },
              itemBuilder: (context, i) => Padding(
                // The row clips at its top edge, flush against a resting
                // cover; the lift reserve pads every item down from it.
                padding: EdgeInsets.only(
                  top: DesktopCarousel.liftRoom,
                  right: i == count - 1 ? 0 : spacing,
                ),
                child: widget.loading
                    ? const _CoverSkeleton()
                    : widget.itemBuilder(context, i),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sizes the carousel's scroll view from the width it's given: the row's
/// width from [geometry], its height from [itemHeight] at that geometry's
/// item width, plus the lift reserve. At layout time, so a change of width
/// never rebuilds anything.
class _CarouselRow extends SingleChildRenderObjectWidget {
  final CarouselGeometry Function(double width) geometry;
  final double Function(double itemWidth) itemHeight;

  const _CarouselRow({
    required this.geometry,
    required this.itemHeight,
    required super.child,
  });

  @override
  _RenderCarouselRow createRenderObject(BuildContext context) =>
      _RenderCarouselRow(geometry, itemHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderCarouselRow row) {
    row
      ..geometry = geometry
      ..itemHeight = itemHeight;
  }
}

class _RenderCarouselRow extends RenderProxyBox {
  _RenderCarouselRow(this._geometry, this._itemHeight);

  CarouselGeometry Function(double width) _geometry;
  set geometry(CarouselGeometry Function(double width) value) {
    _geometry = value;
    markNeedsLayout();
  }

  double Function(double itemWidth) _itemHeight;
  set itemHeight(double Function(double itemWidth) value) {
    _itemHeight = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final g = _geometry(width);
    final height = _itemHeight(g.itemWidth) + DesktopCarousel.liftRoom;
    child!.layout(BoxConstraints.tight(Size(g.rowWidth, height)));
    size = constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final g = _geometry(constraints.maxWidth);
    return constraints.constrain(
      Size(
        constraints.maxWidth,
        _itemHeight(g.itemWidth) + DesktopCarousel.liftRoom,
      ),
    );
  }
}

class _CoverSkeleton extends StatelessWidget {
  const _CoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.surfaceRaised,
      highlightColor: context.colors.surface,
      period: const Duration(milliseconds: 1400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 9),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
