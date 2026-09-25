import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [body] with [trailing] beside it while [body] keeps at least
/// [minBodyWidth], and [trailing] beneath it when it wouldn't — decided at
/// layout time, so a resize never rebuilds it.
///
/// For text next to a control (a setting and its switch or dropdown, a card
/// and its button): the control's width depends on its label, the language
/// and the text size, so no single breakpoint fits every case. This measures
/// it instead.
///
/// An optional [leading] (an icon) sits before [body]; a [trailing] moved
/// beneath lines up with [body], not with [leading].
class BesideOrBelow extends MultiChildRenderObjectWidget {
  final double minBodyWidth;
  final double gap;
  final double stackGap;

  /// Beside each other, top-align the children rather than centring them.
  final bool alignTop;

  BesideOrBelow({
    super.key,
    Widget? leading,
    required Widget body,
    required Widget trailing,
    this.minBodyWidth = 200,
    this.gap = 16,
    this.stackGap = 10,
    this.alignTop = false,
  }) : _hasLeading = leading != null,
       super(children: [?leading, body, trailing]);

  final bool _hasLeading;

  @override
  RenderBesideOrBelow createRenderObject(BuildContext context) =>
      RenderBesideOrBelow(
        hasLeading: _hasLeading,
        minBodyWidth: minBodyWidth,
        gap: gap,
        stackGap: stackGap,
        alignTop: alignTop,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBesideOrBelow renderObject,
  ) {
    renderObject
      ..hasLeading = _hasLeading
      ..minBodyWidth = minBodyWidth
      ..gap = gap
      ..stackGap = stackGap
      ..alignTop = alignTop;
  }
}

class _BesideParentData extends ContainerBoxParentData<RenderBox> {}

class RenderBesideOrBelow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideParentData> {
  RenderBesideOrBelow({
    required bool hasLeading,
    required double minBodyWidth,
    required double gap,
    required double stackGap,
    required bool alignTop,
  }) : _alignTop = alignTop,
       _hasLeading = hasLeading,
       _minBodyWidth = minBodyWidth,
       _gap = gap,
       _stackGap = stackGap;

  bool _hasLeading;
  set hasLeading(bool v) {
    if (v == _hasLeading) return;
    _hasLeading = v;
    markNeedsLayout();
  }

  double _minBodyWidth;
  set minBodyWidth(double v) {
    if (v == _minBodyWidth) return;
    _minBodyWidth = v;
    markNeedsLayout();
  }

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _stackGap;
  set stackGap(double v) {
    if (v == _stackGap) return;
    _stackGap = v;
    markNeedsLayout();
  }

  bool _alignTop;
  set alignTop(bool v) {
    if (v == _alignTop) return;
    _alignTop = v;
    markNeedsLayout();
  }

  /// Whether [trailing] is currently beside [body] (false: beneath it).
  bool beside = true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BesideParentData) {
      child.parentData = _BesideParentData();
    }
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    assert(constraints.hasBoundedWidth, 'BesideOrBelow needs a bounded width.');
    final leading = _hasLeading ? firstChild : null;
    final body = leading == null ? firstChild! : childAfter(leading)!;
    final trailing = childAfter(body)!;
    final width = constraints.maxWidth;

    Size lay(RenderBox child, BoxConstraints c) => dry
        ? child.getDryLayout(c)
        : (child..layout(c, parentUsesSize: true)).size;
    void place(RenderBox child, Offset offset) {
      if (!dry) (child.parentData! as _BesideParentData).offset = offset;
    }

    final leadingSize = leading == null
        ? Size.zero
        : lay(leading, BoxConstraints(maxWidth: width));
    final bodyLeft = leading == null ? 0.0 : leadingSize.width + _gap;
    final room = (width - bodyLeft).clamp(0.0, double.infinity);
    final trailingSize = lay(trailing, BoxConstraints(maxWidth: room));

    final besideWidth = room - _gap - trailingSize.width;
    final fits = besideWidth >= _minBodyWidth;
    if (!dry) beside = fits;

    if (fits) {
      final bodySize = lay(body, BoxConstraints(maxWidth: besideWidth));
      final height = [
        leadingSize.height,
        bodySize.height,
        trailingSize.height,
      ].reduce((a, b) => a > b ? a : b);
      double y(Size child) => _alignTop ? 0 : (height - child.height) / 2;
      if (leading != null) place(leading, Offset(0, y(leadingSize)));
      place(body, Offset(bodyLeft, y(bodySize)));
      place(trailing, Offset(width - trailingSize.width, y(trailingSize)));
      return constraints.constrain(Size(width, height));
    }

    final bodySize = lay(body, BoxConstraints(maxWidth: room));
    final top = bodySize.height > leadingSize.height
        ? bodySize.height
        : leadingSize.height;
    if (leading != null) {
      place(leading, Offset(0, (bodySize.height - leadingSize.height) / 2));
    }
    place(body, Offset(bodyLeft, 0));
    place(trailing, Offset(bodyLeft, top + _stackGap));
    return constraints.constrain(
      Size(width, top + _stackGap + trailingSize.height),
    );
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
