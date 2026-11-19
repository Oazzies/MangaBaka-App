import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Unlike [IndexedStack], hidden pages skip layout on resize and see a frozen [MediaQuery].
class ActivePageStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const ActivePageStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _ActivePageStackLayout(
      index: index,
      children: [
        for (var i = 0; i < children.length; i++)
          _PageSlot(active: i == index, child: children[i]),
      ],
    );
  }
}

class _PageSlot extends StatefulWidget {
  final bool active;
  final Widget child;

  const _PageSlot({required this.active, required this.child});

  @override
  State<_PageSlot> createState() => _PageSlotState();
}

class _PageSlotState extends State<_PageSlot> {
  MediaQueryData? _shown;

  @override
  Widget build(BuildContext context) {
    // responsive-ok: the whole data is what's frozen for hidden pages.
    final live = MediaQuery.of(context);
    if (widget.active || _shown == null) _shown = live;
    // Same structure active or not, so switching pages never remounts one.
    return ExcludeFocus(
      excluding: !widget.active,
      child: TickerMode(
        enabled: widget.active,
        child: MediaQuery(data: _shown!, child: widget.child),
      ),
    );
  }
}

class _ActivePageStackLayout extends MultiChildRenderObjectWidget {
  final int index;

  const _ActivePageStackLayout({required this.index, super.children});

  @override
  MultiChildRenderObjectElement createElement() =>
      _ActivePageStackElement(this);

  @override
  RenderActivePageStack createRenderObject(BuildContext context) =>
      RenderActivePageStack(index: index);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderActivePageStack renderObject,
  ) {
    renderObject.index = index;
  }
}

class _ActivePageStackElement extends MultiChildRenderObjectElement {
  _ActivePageStackElement(_ActivePageStackLayout super.widget);

  // Tests' finders (and the inspector) treat the hidden pages as offstage.
  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final index = (widget as _ActivePageStackLayout).index;
    if (index >= 0 && index < children.length) {
      visitor(children.elementAt(index));
    }
  }
}

class _PageParentData extends ContainerBoxParentData<RenderBox> {}

class RenderActivePageStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PageParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PageParentData> {
  RenderActivePageStack({required int index}) : _index = index;

  int _index;
  int get index => _index;
  set index(int value) {
    if (_index == value) return;
    _index = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  RenderBox? get _active {
    var child = firstChild;
    for (var i = 0; child != null && i < _index; i++) {
      child = childAfter(child);
    }
    return child;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PageParentData) {
      child.parentData = _PageParentData();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      constraints.hasBoundedWidth && constraints.hasBoundedHeight,
      'ActivePageStack fills its space and needs bounded constraints.',
    );
    return constraints.biggest;
  }

  @override
  void performLayout() {
    _active?.layout(BoxConstraints.tight(size));
  }

  @override
  bool paintsChild(RenderBox child) => identical(child, _active);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = _active;
    if (child != null) context.paintChild(child, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _active?.hitTest(result, position: position) ?? false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final child = _active;
    if (child != null) visitor(child);
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
  @override
  double computeMinIntrinsicHeight(double width) => 0;
  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
