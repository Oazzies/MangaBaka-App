import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';

/// Search beside sort. Too narrow for the sort pill's label, sort shrinks to its glyph.
class ListToolbar<T> extends StatelessWidget {
  static const double _roomyWidth = 560;

  final Widget search;
  final String sortLabel;
  final T sort;
  final List<(T, String)> sortOptions;
  final ValueChanged<T> onSort;
  final EdgeInsetsGeometry padding;

  const ListToolbar({
    super.key,
    required this.search,
    required this.sortLabel,
    required this.sort,
    required this.sortOptions,
    required this.onSort,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: DerivedLayoutBuilder<bool>(
        derive: (c) => c.maxWidth >= _roomyWidth,
        builder: (context, roomy) => Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            if (roomy)
              MbDropdown<T>(
                label: sortLabel,
                icon: Icons.sort_rounded,
                value: sort,
                options: sortOptions,
                onChanged: onSort,
              )
            else
              _SortButton<T>(
                label: sortLabel,
                sort: sort,
                options: sortOptions,
                onSort: onSort,
              ),
          ],
        ),
      ),
    );
  }
}

class _SortButton<T> extends StatelessWidget {
  final String label;
  final T sort;
  final List<(T, String)> options;
  final ValueChanged<T> onSort;

  const _SortButton({
    required this.label,
    required this.sort,
    required this.options,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: c.surfaceRaised,
        shape: const StadiumBorder(),
        child: IconButton(
          key: const ValueKey('list_sort_button'),
          tooltip: label,
          icon: Icon(Icons.sort_rounded, size: 20, color: c.text),
          onPressed: () => showMbOptionSheet<T>(
            context,
            title: label,
            options: options,
            current: sort,
            onSelected: onSort,
          ),
        ),
      ),
    );
  }
}
