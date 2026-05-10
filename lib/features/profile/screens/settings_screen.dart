import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/screens/advanced_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';

import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/display_settings_group.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_settings_group.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/information_settings_group.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';

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
            centerTitle: true,
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
              DisplaySettingsGroup(l10n: l10n),
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('list')),
              ListSettingsGroup(l10n: l10n),
              const SizedBox(height: 16),
              SettingsSectionHeader(title: l10n.translate('content')),
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.filter_alt_outlined,
                    title: l10n.translate('content_preferences'),
                    subtitle: ContentPreferencesDialogs.getContentPreferencesText(
                      SettingsManager().contentPreferences,
                    ),
                    onTap: () =>
                        ContentPreferencesDialogs.showContentPreferencesDialog(context),
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
                          final shouldLogout = await LogoutDialog.showLogoutConfirmationDialog(context);
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
              InformationSettingsGroup(l10n: l10n),
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
