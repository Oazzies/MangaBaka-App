import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';

class LicensedChip extends StatelessWidget {
  const LicensedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return MiniBadge(
      text: 'Licensed',
      icon: Icons.verified_user_outlined,
      tooltip: LocalizationService().translate('licensed_status'),
    );
  }
}
