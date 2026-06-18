import 'dart:math';
import 'package:flutter/material.dart';

class DynamicRowHeightGrid extends StatelessWidget {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool shrinkWrap;

  const DynamicRowHeightGrid({
    super.key,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.physics,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();
    
    final int rowCount = (itemCount / crossAxisCount).ceil();

    return ListView.builder(
      controller: controller,
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final int startIndex = rowIndex * crossAxisCount;
        final int endIndex = min(startIndex + crossAxisCount, itemCount);

        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : mainAxisSpacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(crossAxisCount, (colIndex) {
                final int itemIndex = startIndex + colIndex;
                final double leftPadding = colIndex * crossAxisSpacing / crossAxisCount;
                final double rightPadding = (crossAxisCount - 1 - colIndex) * crossAxisSpacing / crossAxisCount;

                final Widget childWidget = itemIndex < endIndex
                    ? itemBuilder(context, itemIndex)
                    : const SizedBox.shrink();

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leftPadding,
                      right: rightPadding,
                    ),
                    child: childWidget,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
