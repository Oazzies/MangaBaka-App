import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

class LicensedChip extends StatelessWidget {
  const LicensedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.euro, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text('Licensed'),
        ],
      ),
    );
  }
}