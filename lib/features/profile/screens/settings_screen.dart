import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/profile/screens/translation_credits_screen.dart';
import 'package:bakahyou/features/profile/screens/advanced_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/profile/widgets/settings_dialogs.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/profile/widgets/settings_components.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

import 'package:bakahyou/utils/localization/localization_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeManager(),
        SettingsManager(),
        LocalizationService(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final auth = getIt<ProfileAuthService>();
        
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          appBar: AppBar(
// ... (omitted lines for brevity, but I will include them in the final replacement)
            title: Text(
              l10n.translate('settings'),
              style: TextStyle(color: AppConstants.textColor),
            ),
            backgroundColor: AppConstants.primaryBackground,
            iconTheme: IconThemeData(color: AppConstants.textColor),
            elevation: 0,
          ),
          body: ListView(
            padding: EdgeInsets.only(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              top: 8,
              bottom: 80, // Padding for system navbar / player etc
            ),
            children: [
              SettingsSectionHeader(title: l10n.translate('display')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.brightness_6_outlined,
                    title: l10n.translate('theme_mode'),
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
                    title: l10n.translate('app_theme'),
                    subtitle: SettingsDialogs.getThemeName(
                      ThemeManager().currentTheme,
                    ),
                    onTap: () =>
                        SettingsDialogs.showThemeSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.language_outlined,
                    title: l10n.translate('language'),
                    subtitle: SettingsDialogs.getLanguageName(l10n.currentLanguage),
                    onTap: () => SettingsDialogs.showLanguageSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.home_outlined,
                    title: l10n.translate('start_page'),
                    subtitle: SettingsDialogs.getAppStartPageName(
                      SettingsManager().defaultStartPage,
                    ),
                    onTap: () =>
                        SettingsDialogs.showAppStartPageSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.tune_outlined,
                    title: l10n.translate('rating_step'),
                    subtitle: SettingsDialogs.getRatingSliderStepName(
                      SettingsManager().ratingSliderStep,
                    ),
                    onTap: () =>
                        SettingsDialogs.showRatingSliderStepSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.library_add_outlined,
                    title: l10n.translate('library_default'),
                    subtitle: SettingsDialogs.getLibraryTabName(
                      SettingsManager().addLibraryDefaultTab,
                    ),
                    onTap: () =>
                        SettingsDialogs.showAddLibraryDefaultTabSelectionDialog(context),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('list')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.translate_outlined,
                    title: l10n.translate('title_language'),
                    subtitle: SettingsDialogs.getTitleLanguageName(
                      SettingsManager().defaultTitleLanguage,
                    ),
                    onTap: () =>
                        SettingsDialogs.showTitleLanguageSelectionDialog(context),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsSwitchItem(
                    icon: Icons.call_split_outlined,
                    title: l10n.translate('separate_list'),
                    subtitle: l10n.translate('separate_list_subtext'),
                    value: SettingsManager().separateListStyles,
                    onChanged: (value) =>
                        SettingsManager().setSeparateListStyles(value),
                    isLast: !SettingsManager().separateListStyles,
                  ),
                  if (SettingsManager().separateListStyles) ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.view_list_outlined,
                      title: l10n.translate('library_list_style'),
                      subtitle: SettingsDialogs.getListStyleName(
                        SettingsManager().libraryListStyle,
                      ),
                      onTap: () =>
                          SettingsDialogs.showLibraryListStyleSelectionDialog(context),
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.grid_view_outlined,
                      title: l10n.translate('browse_list_style'),
                      subtitle: SettingsDialogs.getListStyleName(
                        SettingsManager().browseListStyle,
                      ),
                      onTap: () =>
                          SettingsDialogs.showBrowseListStyleSelectionDialog(context),
                      isLast: true,
                    ),
                  ] else ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.view_list_outlined,
                      title: l10n.translate('list_style'),
                      subtitle: SettingsDialogs.getListStyleName(
                        SettingsManager().currentListStyle,
                      ),
                      onTap: () =>
                          SettingsDialogs.showListStyleSelectionDialog(context),
                      isLast: true,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('content')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.filter_alt_outlined,
                    title: l10n.translate('content_preferences'),
                    subtitle: SettingsDialogs.getContentPreferencesText(
                      SettingsManager().contentPreferences,
                    ),
                    onTap: () =>
                        SettingsDialogs.showContentPreferencesDialog(context),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsSwitchItem(
                    icon: Icons.library_books_outlined,
                    title: l10n.translate('hide_library'),
                    subtitle: l10n.translate('hide_library_subtext'),
                    value: SettingsManager().hideLibrarySeriesInBrowse,
                    onChanged: (value) =>
                        SettingsManager().setHideLibrarySeriesInBrowse(value),
                    isLast: true,
                  ),
                ],
              ),
              // const SizedBox(height: 16),
              // SettingsSectionHeader(title: l10n.translate('notifications')),
              // SettingsGroup(
              //   children: [
              //     SettingsSwitchItem(
              //       icon: Icons.notifications_outlined,
              //       title: l10n.translate('push_notifications'),
              //       subtitle: l10n.translate('push_notifications_subtext'),
              //       value: SettingsManager().pushNotifications,
              //       onChanged: (value) =>
              //           SettingsManager().setPushNotifications(value),
              //       isFirst: true,
              //       isLast: true,
              //     ),
              //   ],
              // ),
              if (auth.isLoggedIn) ...[
                const SizedBox(height: 16),
                SettingsSectionHeader(title: l10n.translate('account')),
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.manage_accounts_outlined,
                      title: l10n.translate('account_settings'),
                      subtitle: l10n.translate('account_settings_subtext'),
                      onTap: () => launchUrl(
                        Uri.parse('https://mangabaka.org/my/settings/profile'),
                        mode: LaunchMode.externalApplication,
                      ),
                      trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
                      isFirst: true,
                    ),
                    const SettingsDivider(),
                      SettingsItem(
                        icon: Icons.logout_outlined,
                        title: l10n.translate('logout'),
                        subtitle: l10n.translate('logout_subtext'),
                        onTap: () async {
                          final shouldLogout = await SettingsDialogs.showLogoutConfirmationDialog(context);
                          if (shouldLogout == true) {
                            await getIt<ProfileAuthService>().logout();
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        isLast: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('information')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.discord,
                    title: l10n.translate('discord'),
                    onTap: () => launchUrl(
                      Uri.parse('https://mangabaka.org/discord'),
                      mode: LaunchMode.externalApplication,
                    ),
                    trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.code,
                    title: l10n.translate('github'),
                    onTap: () => launchUrl(
                      Uri.parse('https://github.com/Oazzies/BakaHyou'),
                      mode: LaunchMode.externalApplication,
                    ),
                    trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.info_outline,
                    title: l10n.translate('version'),
                    subtitle: AppConstants.appVersion,
                    onTap: null,
                    trailing: const SizedBox.shrink(),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.person_outline,
                    title: l10n.translate('developed_by'),
                    subtitle: 'Oazzies',
                    onTap: () => launchUrl(
                      Uri.parse('https://github.com/Oazzies'),
                      mode: LaunchMode.externalApplication,
                    ),
                    trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.translate,
                    title: l10n.translate('translation_credits'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TranslationCreditsScreen(),
                        ),
                      );
                    },
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.open_in_browser_outlined,
                    title: l10n.translate('open_links'),
                    subtitle: l10n.translate('open_links_subtitle'),
                    onTap: () async {
                      if (Platform.isAndroid) {
                        final intent = AndroidIntent(
                          action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
                          data: 'package:dev.oazzies.bakahyou',
                        );
                        await intent.launch();
                      } else {
                        await openAppSettings();
                      }
                    },
                    trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('advanced_settings')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.settings_applications,
                    title: l10n.translate('advanced_settings'),
                    subtitle: l10n.translate('advanced_settings_subtitle'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedSettingsScreen(),
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
