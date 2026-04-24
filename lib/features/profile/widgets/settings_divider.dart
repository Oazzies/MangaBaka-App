import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppConstants.borderColor.withValues(alpha: 0.2),
      indent: 48,
    );
  }
}
