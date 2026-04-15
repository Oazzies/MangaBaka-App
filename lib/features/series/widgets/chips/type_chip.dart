import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

class TypeChip extends StatelessWidget {
  final String type;
  const TypeChip({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    if (type.isEmpty) return SizedBox.shrink();
    final formattedType = type[0].toUpperCase() + type.substring(1).toLowerCase();
    return ChipBase(
      label: Text(formattedType),
    );
  }
}