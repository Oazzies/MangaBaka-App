import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// A [LayoutBuilder] for decisions: [derive] reduces the constraints to a
/// value (a breakpoint tier, a column count, a flag), and [builder] only runs
/// again when that value changes.
///
/// A plain [LayoutBuilder] rebuilds its whole subtree on every change of
/// constraints — every frame of a window resize — even when all it does with
/// them is pick between two layouts. This keeps the subtree as it is while
/// the decision stands, so a resize costs only the relayout of what's already
/// built.
///
/// [builder] is called with this widget's own context, so what it reads from
/// the tree (theme, translations, media query) is tracked here: a change to
/// any of it rebuilds as usual. [T] must implement `==` meaningfully — use a
/// number, an enum, a bool or a record, not a list.
class DerivedLayoutBuilder<T> extends StatefulWidget {
  final T Function(BoxConstraints constraints) derive;
  final Widget Function(BuildContext context, T value) builder;

  const DerivedLayoutBuilder({
    super.key,
    required this.derive,
    required this.builder,
  });

  @override
  State<DerivedLayoutBuilder<T>> createState() =>
      _DerivedLayoutBuilderState<T>();
}

class _DerivedLayoutBuilderState<T> extends State<DerivedLayoutBuilder<T>> {
  late T _value;
  Widget? _built;

  @override
  Widget build(BuildContext context) {
    // Rebuilt for a reason other than the constraints (new configuration,
    // a dependency changed): the cached subtree is stale.
    _built = null;
    return LayoutBuilder(
      builder: (_, constraints) {
        final value = widget.derive(constraints);
        if (_built == null || value != _value) {
          _value = value;
          _built = widget.builder(context, value);
        }
        return _built!;
      },
    );
  }
}

/// [DerivedLayoutBuilder] for slivers: [derive] reduces the
/// [SliverConstraints] (typically [SliverConstraints.crossAxisExtent]) to a
/// value, and [builder] only runs again when that value changes.
class DerivedSliverLayoutBuilder<T> extends StatefulWidget {
  final T Function(SliverConstraints constraints) derive;
  final Widget Function(BuildContext context, T value) builder;

  const DerivedSliverLayoutBuilder({
    super.key,
    required this.derive,
    required this.builder,
  });

  @override
  State<DerivedSliverLayoutBuilder<T>> createState() =>
      _DerivedSliverLayoutBuilderState<T>();
}

class _DerivedSliverLayoutBuilderState<T>
    extends State<DerivedSliverLayoutBuilder<T>> {
  late T _value;
  Widget? _built;

  @override
  Widget build(BuildContext context) {
    _built = null;
    return SliverLayoutBuilder(
      builder: (_, constraints) {
        final value = widget.derive(constraints);
        if (_built == null || value != _value) {
          _value = value;
          _built = widget.builder(context, value);
        }
        return _built!;
      },
    );
  }
}
