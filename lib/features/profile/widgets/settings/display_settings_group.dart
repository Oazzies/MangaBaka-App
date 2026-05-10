import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/theme_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class DisplaySettingsGroup extends StatelessWidget {
  final LocalizationService l10n;

  const DisplaySettingsGroup({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.brightness_6_outlined,
          title: l10n.translate('theme_mode'),
          subtitle: ThemeDialogs.getThemeModeName(
            ThemeManager().currentThemeMode,
          ),
          onTap: () => ThemeDialogs.showThemeModeSelectionDialog(context),
          isFirst: true,
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.palette_outlined,
          title: l10n.translate('app_theme'),
          subtitle: ThemeDialogs.getThemeName(
            ThemeManager().currentTheme,
          ),
          onTap: () => ThemeDialogs.showThemeSelectionDialog(context),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.language_outlined,
          title: l10n.translate('language'),
          subtitle: GeneralSettingsDialogs.getLanguageName(l10n.currentLanguage),
          onTap: () => GeneralSettingsDialogs.showLanguageSelectionDialog(context),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.home_outlined,
          title: l10n.translate('start_page'),
          subtitle: GeneralSettingsDialogs.getAppStartPageName(
            SettingsManager().defaultStartPage,
          ),
          onTap: () => GeneralSettingsDialogs.showAppStartPageSelectionDialog(context),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.tune_outlined,
          title: l10n.translate('rating_step'),
          subtitle: GeneralSettingsDialogs.getRatingSliderStepName(
            SettingsManager().ratingSliderStep,
          ),
          onTap: () => GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(context),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.library_add_outlined,
          title: l10n.translate('library_default'),
          subtitle: GeneralSettingsDialogs.getLibraryTabName(
            SettingsManager().addLibraryDefaultTab,
          ),
          onTap: () => GeneralSettingsDialogs.showAddLibraryDefaultTabSelectionDialog(context),
          isLast: true,
        ),
      ],
    );
  }
}
