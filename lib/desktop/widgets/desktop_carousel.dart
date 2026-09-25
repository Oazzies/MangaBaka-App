import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A titled horizontal row with previous/next buttons.
///
/// A mouse wheel scrolls vertically, so a phone-style swipe rail is close to
/// unusable on desktop: the only ways along it were a trackpad or dragging the
/// scrollbar. The arrow buttons page by most of a viewport.
class DesktopCarousel extends StatefulWidget {
  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double height;
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
    required this.height,
    this.spacing = 18,
    this.trailing,
    this.onViewAll,
    this.loading = false,
    this.onNearEnd,
  });

  @override
  State<DesktopCarousel> createState() => _DesktopCarouselState();
}

class _DesktopCarouselState extends State<DesktopCarousel> {
  /// Room reserved above each cover, inside the row's clipped viewport, so a
  /// hovered cover's lift has somewhere to go without its top edge being
  /// clipped off.
  static const double _liftRoom = 10;

  final ScrollController _scroll = ScrollController();
  bool _canBack = false;
  bool _canForward = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(covariant DesktopCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A caller (e.g. the profile page) may resize covers to keep the row
    // exactly filling its width as the window is resized. That changes the
    // item boundaries under a scroll position that hasn't moved — a row
    // scrolled a page in would land mid-item until realigned, breaking the
    // edge-to-edge fit while live-resizing.
    if (oldWidget.itemWidth != widget.itemWidth ||
        oldWidget.spacing != widget.spacing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _realign());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Snaps to the nearest item boundary under the current item size —
  /// see [didUpdateWidget].
  void _realign() {
    if (!_scroll.hasClients || !mounted) return;
    final p = _scroll.position;
    final step = widget.itemWidth + widget.spacing;
    final aligned = (p.pixels / step).round() * step;
    final target = aligned.clamp(0.0, p.maxScrollExtent);
    if ((target - p.pixels).abs() > 0.5) {
      _scroll.jumpTo(target);
    }
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
    if (p.pixels > p.maxScrollExtent - widget.itemWidth * 3) {
      widget.onNearEnd?.call();
    }
  }

  /// How many whole items (item + separator) fit in [width].
  int _itemsPerWidth(double width) {
    final step = widget.itemWidth + widget.spacing;
    // The tiny epsilon guards against a caller-supplied itemWidth chosen to
    // fill `width` exactly — floating-point division can land a hair under
    // the true integer count and floor() would then drop a whole item.
    return (((width + widget.spacing) / step + 1e-6).floor()).clamp(
      1,
      1 << 30,
    );
  }

  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final step = widget.itemWidth + widget.spacing;
    // Page by a whole number of items so the row always lands on an item
    // boundary — paging by a raw fraction of the viewport drifts out of
    // alignment, leaving a different number of partially-cut-off cards
    // visible on each click. (+spacing before dividing: the viewport never
    // needs to fit a trailing separator after the last item — see the
    // matching layout math in build().)
    final itemsPerPage = _itemsPerWidth(p.viewportDimension);
    // Snap to the boundary at-or-before the current position — rounding to
    // the *nearest* boundary would sometimes snap forward past a clamped
    // partial last page, leaving every other page slightly misaligned.
    final aligned = (p.pixels / step).floor() * step;
    final target = (aligned + direction * itemsPerPage * step).clamp(
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
    final count = widget.loading ? 8 : widget.itemCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionTitle(
          title: widget.title,
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
        const SizedBox(height: 8),
        // The row clips at its own top edge (see clipBehavior below), which
        // sits flush against a resting cover with no room to spare — a
        // hovered cover lifts a few px and gets its top sliced off right
        // there. _liftRoom pads every item down from the clip edge by more
        // than the lift, inside the clipped area, so there's actually
        // something to lift into. The extra height keeps the row's bottom
        // (captions) from being squeezed by that padding.
        SizedBox(
          height: widget.height + _liftRoom,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final step = widget.itemWidth + widget.spacing;
              // Narrow the row to the widest whole-item multiple that fits.
              // Sizing it to the full available width let the row land
              // mid-item, so the trailing card was cut off by the clip
              // instead of just being hidden past the edge.
              final wholeItems = _itemsPerWidth(constraints.maxWidth);
              final rowWidth = (wholeItems * step - widget.spacing).clamp(
                0.0,
                constraints.maxWidth,
              );
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: rowWidth,
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _update(),
                      );
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      // Clip.none let cards paint outside this row's own
                      // width — on the profile page that meant scrolled-in
                      // covers could spill past the main column and
                      // overlap the sidebar.
                      clipBehavior: Clip.hardEdge,
                      itemCount: count,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: widget.spacing),
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(top: _liftRoom),
                        child: widget.loading
                            ? _CoverSkeleton(width: widget.itemWidth)
                            : widget.itemBuilder(context, i),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoverSkeleton extends StatelessWidget {
  final double width;

  const _CoverSkeleton({required this.width});

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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 9),
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
