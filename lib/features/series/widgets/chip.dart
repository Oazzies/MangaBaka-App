import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

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
        style:
            labelStyle ??
            TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppConstants.textColor,
            ),
        child: label,
      ),
      backgroundColor: backgroundColor ?? AppConstants.borderColor,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
