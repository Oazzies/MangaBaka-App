import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.border,
      indent: 48,
    );
  }
}
