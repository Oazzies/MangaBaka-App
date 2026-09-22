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
  void dispose() {
    _scroll.dispose();
    super.dispose();
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

  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final target = (p.pixels + direction * p.viewportDimension * 0.85).clamp(
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
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _update());
              return false;
            },
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: count,
              separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
              itemBuilder: widget.loading
                  ? (_, __) => _CoverSkeleton(width: widget.itemWidth)
                  : widget.itemBuilder,
            ),
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
