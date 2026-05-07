import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/navigation/screens/onboarding_screen.dart';
import 'package:bakahyou/features/profile/widgets/settings_components.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppConstants.primaryBackground,
            elevation: 0,
            title: Text(
              l10n.translate('advanced_settings'),
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListenableBuilder(
            listenable: SettingsManager(),
            builder: (context, _) {
              return ListView(
                padding: EdgeInsets.all(AppConstants.horizontalPadding),
                children: [
                  SettingsGroup(
                    children: [
                      SettingsItem(
                        icon: Icons.replay_outlined,
                        title: l10n.translate('redo_onboarding'),
                        subtitle: l10n.translate('redo_onboarding_subtitle'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingScreen(isRedoing: true),
                            ),
                          );
                        },
                        isFirst: true,
                      ),
                      const SettingsDivider(),
                      SettingsSwitchItem(
                        icon: Icons.search,
                        title: l10n.translate('auto_suggest_browse'),
                        subtitle: l10n.translate('auto_suggest_browse_subtitle'),
                        value: SettingsManager().autoSuggestBrowse,
                        onChanged: (val) => SettingsManager().setAutoSuggestBrowse(val),
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
