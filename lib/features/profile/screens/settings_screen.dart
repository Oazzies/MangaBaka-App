import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/navigation/screens/onboarding_screen.dart';
import 'package:bakahyou/features/profile/widgets/settings_components.dart';
import 'package:bakahyou/features/profile/widgets/settings_dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), SettingsManager()]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: TextStyle(color: AppConstants.textColor),
            ),
            backgroundColor: AppConstants.primaryBackground,
            iconTheme: IconThemeData(color: AppConstants.textColor),
            elevation: 0,
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
              vertical: 8,
            ),
            children: [
              const SettingsSectionHeader(title: 'Appearance'),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.brightness_6_outlined,
                    title: 'Theme Mode',
                    subtitle: SettingsDialogs.getThemeModeName(
                      ThemeManager().currentThemeMode,
                    ),
                    onTap: () =>
                        SettingsDialogs.showThemeModeSelectionDialog(context),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'App Theme',
                    subtitle: SettingsDialogs.getThemeName(
                      ThemeManager().currentTheme,
                    ),
                    onTap: () =>
                        SettingsDialogs.showThemeSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.view_list_outlined,
                    title: 'List Style',
                    subtitle: SettingsDialogs.getListStyleName(
                      SettingsManager().currentListStyle,
                    ),
                    onTap: () =>
                        SettingsDialogs.showListStyleSelectionDialog(context),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SettingsSectionHeader(title: 'Content'),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.filter_alt_outlined,
                    title: 'Content Preferences',
                    subtitle: SettingsDialogs.getContentPreferencesText(
                      SettingsManager().contentPreferences,
                    ),
                    onTap: () =>
                        SettingsDialogs.showContentPreferencesDialog(context),
                    isFirst: true,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SettingsSectionHeader(title: 'Browse'),
              SettingsGroup(
                children: [
                  SettingsSwitchItem(
                    icon: Icons.library_books_outlined,
                    title: 'Hide Library Series',
                    subtitle:
                        'Exclude series already in your library from Browse search results',
                    value: SettingsManager().hideLibrarySeriesInBrowse,
                    onChanged: (value) =>
                        SettingsManager().setHideLibrarySeriesInBrowse(value),
                    isFirst: true,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SettingsSectionHeader(title: 'Other'),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.replay_outlined,
                    title: 'Redo Onboarding',
                    subtitle: 'Restart the initial app setup process',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const OnboardingScreen(isRedoing: true),
                        ),
                      );
                    },
                    isFirst: true,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
