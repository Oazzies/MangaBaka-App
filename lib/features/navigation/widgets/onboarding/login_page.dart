import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';

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

  Widget _buildConnectedBadge(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.successColor.withValues(alpha: 0.3),
        ),
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
    );
  }

  Widget _buildLoginButton(LocalizationService localization, bool isShort) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoggingIn ? null : onLogin,
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.accentColor,
          foregroundColor: AppConstants.primaryBackground,
          padding: EdgeInsets.symmetric(vertical: isShort ? 12 : 16),
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
    );
  }

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
              icon: Icons.account_circle_rounded,
              title: localization.translate('onboarding_login_title'),
              subtitle: localization.translate('onboarding_login_subtitle'),
              isShort: isShort,
              action: isLoggedIn
                  ? _buildConnectedBadge(localization)
                  : _buildLoginButton(localization, isShort),
            );
          },
        );
      },
    );
  }
}
