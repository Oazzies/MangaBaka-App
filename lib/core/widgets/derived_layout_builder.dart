import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// [T] needs a meaningful `==`: a number, enum, bool or record, not a list.
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
    // Rebuilt for a reason other than constraints: the cached subtree is stale.
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
