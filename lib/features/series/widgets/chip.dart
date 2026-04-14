import 'package:flutter/material.dart';

class ChipBase extends StatelessWidget {
  final Widget label;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  const ChipBase({
    required this.label,
    this.backgroundColor,
    this.padding,
    this.labelStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: DefaultTextStyle(
        style: labelStyle ??
            const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
        child: label,
      ),
      backgroundColor: backgroundColor ?? const Color(0xFF3f3f46),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}