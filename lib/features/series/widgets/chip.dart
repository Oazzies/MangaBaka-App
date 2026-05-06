import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

/// Base chip widget used across the app for genres, tags, etc.
/// Styled to match the action bar: rounded-rect with secondary background.
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
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTextStyle(
        style: labelStyle ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              height: 1.2,
            ),
        child: label,
      ),
    );
  }
}
