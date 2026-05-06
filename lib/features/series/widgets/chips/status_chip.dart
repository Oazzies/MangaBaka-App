import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    final lower = status.toLowerCase();
    
    Color? color;
    IconData? icon;
    Color? bgColor;

    if (lower == 'releasing') {
      color = AppConstants.successColor;
      icon = Icons.play_arrow_outlined;
      bgColor = AppConstants.successColor.withValues(alpha: 0.1);
    } else if (lower == 'completed') {
      color = AppConstants.infoColor;
      icon = Icons.check_circle_outline_outlined;
      bgColor = AppConstants.infoColor.withValues(alpha: 0.1);
    } else if (lower == 'hiatus') {
      color = AppConstants.warningColor;
      icon = Icons.pause_circle_outline;
      bgColor = AppConstants.warningColor.withValues(alpha: 0.1);
    }

    return MiniBadge(
      text: status,
      icon: icon,
      color: color,
      backgroundColor: bgColor,
    );
  }
}
