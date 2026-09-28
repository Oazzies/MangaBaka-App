import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_hero_layout.dart';

/// Onboarding step that explains and enables the "open MangaBaka links in app"
/// feature. Only shown on Android where intent filters are meaningful.
class OpenLinksPage extends StatelessWidget {
  const OpenLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        return LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 500;
            return OnboardingHeroLayout(
              icon: Icons.open_in_app_rounded,
              title: l10n.translate('onboarding_links_title'),
              subtitle: l10n.translate('onboarding_links_subtitle'),
              isShort: isShort,
              action: SizedBox(
                width: double.infinity,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.translate('open_links'),
                    style: TextStyle(
                      color: context.colors.text,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    l10n.translate('open_links_subtext'),
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  value: settings.openLinksInApp,
                  onChanged: settings.setOpenLinksInApp,
                  activeColor: context.colors.accent,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
