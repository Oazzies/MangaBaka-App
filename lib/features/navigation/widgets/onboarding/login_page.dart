import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class LoginPage extends StatelessWidget {
  final bool isLoggingIn;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  const LoginPage({
    super.key,
    required this.isLoggingIn,
    required this.isLoggedIn,
    required this.onLogin,
  });

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
                  Icons.account_circle_rounded,
                  size: 64,
                  color: AppConstants.accentColor,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                localization.translate('onboarding_login_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localization.translate('onboarding_login_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textMutedColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.successColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppConstants.successColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        localization.translate('onboarding_connected'),
                        style: TextStyle(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoggingIn ? null : onLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: AppConstants.primaryBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoggingIn
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBackground),
                            ),
                          )
                        : Text(localization.translate('onboarding_login_button')),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
