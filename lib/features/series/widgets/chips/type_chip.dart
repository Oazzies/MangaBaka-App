import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';

class TypeChip extends StatelessWidget {
  final String type;
  const TypeChip({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    if (type.isEmpty) return const SizedBox.shrink();
    return MiniBadge(
      text: type,
      icon: Icons.category_outlined,
    );
  }
}
