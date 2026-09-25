import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] when its natural width fits the space available, and
/// [fallback] when it doesn't — decided during layout, every frame, with no
/// rebuild.
///
/// For controls whose width depends on data or on the language (a segmented
/// control over a list of sources, a row of translated labels): rather than
/// guess a breakpoint that is wrong for some language or some data, this
/// measures [child] and swaps in a compact [fallback] only when it would
/// overflow. Both are built; only the one shown is painted, hit-tested and
/// visible to semantics and tests.
class FitOrElse extends MultiChildRenderObjectWidget {
  FitOrElse({super.key, required Widget child, required Widget fallback})
    : super(children: [child, fallback]);

  @override
  MultiChildRenderObjectElement createElement() => _FitOrElseElement(this);

  @override
  RenderFitOrElse createRenderObject(BuildContext context) => RenderFitOrElse();
}

class _FitOrElseElement extends MultiChildRenderObjectElement {
  _FitOrElseElement(FitOrElse super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final render = renderObject as RenderFitOrElse;
    if (children.length == 2) visitor(children.elementAt(render.shownIndex));
  }
}

class _FitParentData extends ContainerBoxParentData<RenderBox> {}

class RenderFitOrElse extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitParentData> {
  /// 0 while the child fits, 1 while the fallback is showing.
  int shownIndex = 0;

  RenderBox? get _shown => shownIndex == 0 ? firstChild : lastChild;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FitParentData) {
      child.parentData = _FitParentData();
    }
  }

  @override
  void performLayout() {
    final primary = firstChild!;
    // Its natural width: as wide as it wants to be, as tall as allowed.
    primary.layout(
      BoxConstraints(maxHeight: constraints.maxHeight),
      parentUsesSize: true,
    );
    final fits = primary.size.width <= constraints.maxWidth + 0.5;
    final index = fits ? 0 : 1;
    if (index != shownIndex) {
      shownIndex = index;
      markNeedsSemanticsUpdate();
    }
    if (fits) {
      size = constraints.constrain(primary.size);
      return;
    }
    final fallback = lastChild!;
    fallback.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(fallback.size);
  }

  @override
  bool paintsChild(RenderBox child) => identical(child, _shown);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = _shown;
    if (child != null) context.paintChild(child, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _shown?.hitTest(result, position: position) ?? false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final child = _shown;
    if (child != null) visitor(child);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _shown?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _shown?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final primary = firstChild!.getDryLayout(
      BoxConstraints(maxHeight: constraints.maxHeight),
    );
    if (primary.width <= constraints.maxWidth + 0.5) {
      return constraints.constrain(primary);
    }
    return constraints.constrain(
      lastChild!.getDryLayout(constraints.loosen()),
    );
  }
}
