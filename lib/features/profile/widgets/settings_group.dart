import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
