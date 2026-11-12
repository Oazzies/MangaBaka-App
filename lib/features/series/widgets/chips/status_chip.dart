import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/status_icons.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    final color = context.colors.forSeriesStatus(status);
    final icon = StatusIcons.forSeriesStatus(status);
    final bgColor = color.withValues(alpha: 0.12);

    return MiniBadge(
      text: status,
      icon: icon,
      color: color,
      backgroundColor: bgColor,
      tooltip: LocalizationService().translate('status'),
    );
  }
}
