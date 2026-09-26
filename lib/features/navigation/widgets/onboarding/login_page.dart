import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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

  Widget _buildConnectedBadge(
    BuildContext context,
    LocalizationService localization,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: context.colors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.colors.background,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            localization.translate('onboarding_connected').toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    LocalizationService localization,
    bool isShort,
  ) {
    return SizedBox(
      width: double.infinity,
      child: MbPrimaryButton(
        busy: isLoggingIn,
        label: localization.translate('onboarding_login_button'),
        onPressed: onLogin,
      ),
    );
  }

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
              icon: Icons.account_circle_rounded,
              title: localization.translate('onboarding_login_title'),
              subtitle: localization.translate('onboarding_login_subtitle'),
              isShort: isShort,
              action: isLoggedIn
                  ? _buildConnectedBadge(context, localization)
                  : _buildLoginButton(context, localization, isShort),
            );
          },
        );
      },
    );
  }
}
