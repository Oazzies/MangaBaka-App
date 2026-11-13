part of 'desktop_carousel.dart';

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
