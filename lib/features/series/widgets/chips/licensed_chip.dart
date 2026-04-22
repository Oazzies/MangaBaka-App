import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LicensedChip extends StatelessWidget {
  LicensedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.euro, size: 16, color: AppConstants.textColor),
          const SizedBox(width: 4),
          Text('Licensed'),
        ],
      ),
    );
  }
}
