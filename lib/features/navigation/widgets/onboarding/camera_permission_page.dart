import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';

class CameraPermissionPage extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const CameraPermissionPage({super.key, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final localization = LocalizationService();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 500;
            return OnboardingHeroLayout(
              icon: Icons.qr_code_scanner_rounded,
              title: localization.translate('onboarding_camera_title'),
              subtitle: localization.translate('onboarding_camera_subtitle'),
              isShort: isShort,
              action: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(localization.translate('onboarding_camera_button')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: AppConstants.primaryBackground,
                    padding: EdgeInsets.symmetric(vertical: isShort ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
