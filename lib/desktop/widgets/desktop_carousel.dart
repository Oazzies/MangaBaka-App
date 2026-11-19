import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_carousel_layout_part.dart';

/// Worked out at layout time, never build time, so a resize never rebuilds an item.
class CarouselGeometry {
  final int count;

  final double itemWidth;

  /// Narrower than the space when items aren't stretched, so the row ends on an item boundary.
  final double rowWidth;

  const CarouselGeometry._(this.count, this.itemWidth, this.rowWidth);

  factory CarouselGeometry.resolve(
    double available, {
    required double targetWidth,
    required double spacing,
    required bool stretch,
  }) {
    final step = targetWidth + spacing;
    // Epsilon: a width fitting n items exactly can land a hair under n, and floor() would drop one.
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

/// A mouse wheel scrolls vertically, so a swipe rail is close to unusable on desktop.
/// Items must fill their [CarouselGeometry.itemWidth] by [itemHeight] slot, not size themselves.
class DesktopCarousel extends StatefulWidget {
  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  final double itemWidth;

  /// Grow items to fill the row with a whole number, edges aligned with what sits above and below.
  final bool stretch;

  final double Function(double itemWidth) itemHeight;

  final double spacing;
  final Widget? trailing;
  final VoidCallback? onViewAll;
  final bool loading;

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

  /// Room inside the clipped row so a hovered cover's lift and shadow are not clipped off.
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
      // Stretching moves item boundaries under an unmoved scroll offset, leaving the row mid-item.
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
    // Floor, not round: rounding could snap forward past a clamped partial last page.
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
          // Tighter than the default 14px; safe because the hover-lift reserve lives inside the row.
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
              // Not Clip.none: on the profile page, scrolled-in covers spilled over the sidebar.
              clipBehavior: Clip.hardEdge,
              itemCount: count,
              itemExtentBuilder: (index, dimensions) {
                if (index >= count) return null;
                final width = _geometry(
                  dimensions.viewportMainAxisExtent,
                ).itemWidth;
                return index == count - 1 ? width : width + spacing;
              },
              itemBuilder: (context, i) => Padding(
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
