import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

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
            centerTitle: true,
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
              return WidgetUtils.responsiveConstraint(
                ListView(
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
                        ),
                        const SettingsDivider(),
                        SettingsSwitchItem(
                          icon: Icons.touch_app_outlined,
                          title: l10n.translate('tap_to_update_progress'),
                          subtitle: l10n.translate('tap_to_update_progress_subtitle'),
                          value: SettingsManager().tapToUpdateProgressInChips,
                          onChanged: (val) => SettingsManager().setTapToUpdateProgressInChips(val),
                        ),
                        const SettingsDivider(),
                        SettingsSwitchItem(
                          icon: Icons.star_outline,
                          title: l10n.translate('tap_to_update_rating'),
                          subtitle: l10n.translate('tap_to_update_rating_subtitle'),
                          value: SettingsManager().tapToUpdateRatingInChips,
                          onChanged: (val) => SettingsManager().setTapToUpdateRatingInChips(val),
                        ),
                        const SettingsDivider(),
                        SettingsItem(
                          icon: Icons.assignment_outlined,
                          title: l10n.translate('view_logs'),
                          subtitle: l10n.translate('view_logs_subtitle'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogsScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
