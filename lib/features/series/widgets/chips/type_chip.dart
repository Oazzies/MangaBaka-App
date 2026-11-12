import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';

import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

class TypeChip extends StatelessWidget {
  final String type;
  const TypeChip({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    if (type.isEmpty) return const SizedBox.shrink();
    final color = context.colors.forSeriesType(type);
    return MiniBadge(
      text: type,
      icon: Icons.category_outlined,
      color: color,
      backgroundColor: color.withValues(alpha: 0.12),
      tooltip: LocalizationService().translate('type'),
    );
  }
}
