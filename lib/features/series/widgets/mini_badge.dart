import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class MiniBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  const MiniBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: 16, 
              color: color ?? AppConstants.textMutedColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color ?? AppConstants.textColor, 
              fontSize: 11, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 0.7,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
