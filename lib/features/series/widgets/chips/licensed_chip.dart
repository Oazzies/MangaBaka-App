import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';

class LicensedChip extends StatelessWidget {
  const LicensedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiniBadge(
      text: 'Licensed',
      icon: Icons.verified_user_outlined,
    );
  }
}
