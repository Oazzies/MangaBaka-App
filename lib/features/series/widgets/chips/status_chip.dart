import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
      color = context.colors.success;
      icon = Icons.play_arrow_outlined;
      bgColor = context.colors.success.withValues(alpha: 0.1);
    } else if (lower == 'completed') {
      color = context.colors.info;
      icon = Icons.check_circle_outline_outlined;
      bgColor = context.colors.info.withValues(alpha: 0.1);
    } else if (lower == 'hiatus') {
      color = context.colors.warning;
      icon = Icons.pause_circle_outline;
      bgColor = context.colors.warning.withValues(alpha: 0.1);
    }

    return MiniBadge(
      text: status,
      icon: icon,
      color: color,
      backgroundColor: bgColor,
      tooltip: LocalizationService().translate('status'),
    );
  }
}
