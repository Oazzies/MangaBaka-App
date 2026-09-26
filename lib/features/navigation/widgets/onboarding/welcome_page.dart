import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final localization = LocalizationService();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 500;
            return OnboardingHeroLayout(
              heroWidget: Image.asset(
                'assets/mangabaka512.png',
                width: isShort ? 64 : 88,
                height: isShort ? 64 : 88,
              ),
              title: localization.translate('app_name'),
              isShort: isShort,
              titleFontSize: 32,
              titleFontWeight: FontWeight.w900,
              titleLetterSpacing: -0.5,
            );
          },
        );
      },
    );
  }
}
