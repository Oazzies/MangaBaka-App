import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class CameraPermissionPage extends StatelessWidget {
  final VoidCallback onRequestPermission;

  const CameraPermissionPage({super.key, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final localization = LocalizationService();
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 64,
                  color: AppConstants.accentColor,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                localization.translate('onboarding_camera_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localization.translate('onboarding_camera_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textMutedColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(localization.translate('onboarding_camera_button')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: AppConstants.primaryBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
