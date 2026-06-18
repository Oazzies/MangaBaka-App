import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

class ChipBase extends StatelessWidget {
  final Widget label;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  final VoidCallback? onTap;

  const ChipBase({
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.padding,
    this.labelStyle,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
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

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: chip,
        ),
      );
    }

    return chip;
  }
}
