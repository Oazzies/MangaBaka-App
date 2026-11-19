import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/library/import/import_export_screen.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

/// Import needs an account, and onboarding's Next does not require signing in.
class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = getIt<ProfileAuthService>();
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), auth]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final isLoggedIn = auth.isLoggedIn;
        return LayoutBuilder(
          builder: (context, constraints) {
            return OnboardingHeroLayout(
              icon: Icons.cloud_upload_rounded,
              title: l10n.translate('onboarding_import_title'),
              subtitle: l10n.translate(
                isLoggedIn
                    ? 'onboarding_import_subtitle'
                    : 'onboarding_import_login_required',
              ),
              isShort: constraints.maxHeight < 500,
              action: isLoggedIn
                  ? SizedBox(
                      width: double.infinity,
                      child: MbPrimaryButton(
                        label: l10n.translate('onboarding_import_button'),
                        onPressed: () => ImportExportScreen.open(context),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
