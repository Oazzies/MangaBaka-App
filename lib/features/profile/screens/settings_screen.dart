import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/screens/settings_category_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/theme_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.translate('settings'),
              style: TextStyle(color: AppConstants.textColor),
            ),
            backgroundColor: AppConstants.primaryBackground,
            iconTheme: IconThemeData(color: AppConstants.textColor),
            centerTitle: true,
            elevation: 0,
          ),
          body: WidgetUtils.responsiveConstraint(
            ListView(
              padding: EdgeInsets.only(
                left: AppConstants.horizontalPadding,
                right: AppConstants.horizontalPadding,
                top: 8,
                bottom: 80,
              ),
              children: [
                // Logo Section
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/mangabaka512.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.settings_outlined,
                      title: l10n.translate('general'),
                      subtitle: l10n.translate('general_settings_subtitle'),
                      onTap: () => _navigateToGeneral(context, l10n),
                      isFirst: true,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.palette_outlined,
                      title: l10n.translate('display'),
                      subtitle: l10n.translate('display_settings_subtitle'),
                      onTap: () => _navigateToDisplay(context, l10n),
                      isFirst: true,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.library_books_outlined,
                      title: l10n.translate('content'),
                      subtitle: l10n.translate('library_settings_subtitle'),
                      onTap: () => _navigateToContent(context, l10n),
                      isFirst: true,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (auth.isLoggedIn) ...[
                  SettingsGroup(
                    children: [
                      SettingsItem(
                        icon: Icons.person_outline,
                        title: l10n.translate('account'),
                        subtitle: l10n.translate('account_settings_subtitle'),
                        onTap: () => _navigateToAccount(context, l10n, auth),
                        isFirst: true,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.code,
                      title: l10n.translate('advanced_settings'),
                      subtitle: l10n.translate('advanced_settings_subtitle'),
                      onTap: () => _navigateToAdvanced(context, l10n),
                      isFirst: true,
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Information Section (at the bottom)
                SettingsGroup(
                  children: [
                    SettingsItem(
                      icon: Icons.discord,
                      title: l10n.translate('discord'),
                      onTap: () => launchUrl(Uri.parse('https://discord.gg/mangabaka'), mode: LaunchMode.externalApplication),
                      trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 18),
                      isFirst: true,
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.code,
                      title: l10n.translate('github'),
                      onTap: () => launchUrl(Uri.parse('https://github.com/oazzies/MangaBaka-App'), mode: LaunchMode.externalApplication),
                      trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 18),
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.info_outline,
                      title: l10n.translate('translation_credits'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TranslationCreditsScreen())),
                      isLast: true,
                    ),
                  ],
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToGeneral(BuildContext context, LocalizationService l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsCategoryScreen(
          title: l10n.translate('general'),
          children: [
            SettingsGroup(
              children: [
                SettingsItem(
                  icon: Icons.language,
                  title: l10n.translate('language'),
                  subtitle: GeneralSettingsDialogs.getLanguageName(l10n.currentLanguage),
                  onTap: () => GeneralSettingsDialogs.showLanguageSelectionDialog(context),
                  isFirst: true,
                ),
                const SettingsDivider(),
                SettingsItem(
                  icon: Icons.start,
                  title: l10n.translate('start_page'),
                  subtitle: GeneralSettingsDialogs.getAppStartPageName(SettingsManager().defaultStartPage),
                  onTap: () => GeneralSettingsDialogs.showAppStartPageSelectionDialog(context),
                ),
                const SettingsDivider(),
                SettingsItem(
                  icon: Icons.translate,
                  title: l10n.translate('title_language'),
                  subtitle: GeneralSettingsDialogs.getTitleLanguageName(SettingsManager().defaultTitleLanguage),
                  onTap: () => GeneralSettingsDialogs.showTitleLanguageSelectionDialog(context),
                ),
                const SettingsDivider(),
                SettingsSwitchItem(
                  icon: Icons.help_outline,
                  title: l10n.translate('show_tooltips'),
                  subtitle: l10n.translate('show_tooltips_subtext'),
                  value: SettingsManager().showTooltips,
                  onChanged: (val) => SettingsManager().setShowTooltips(val),
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
        ),
      ),
    );
  }

  void _navigateToDisplay(BuildContext context, LocalizationService l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: Listenable.merge([ThemeManager(), SettingsManager()]),
          builder: (context, _) => SettingsCategoryScreen(
            title: l10n.translate('display'),
            children: [
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.brightness_6_outlined,
                    title: l10n.translate('theme_mode'),
                    subtitle: ThemeDialogs.getThemeModeName(ThemeManager().currentThemeMode),
                    onTap: () => ThemeDialogs.showThemeModeSelectionDialog(context),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.palette_outlined,
                    title: l10n.translate('app_theme'),
                    subtitle: ThemeDialogs.getThemeName(ThemeManager().currentTheme),
                    onTap: () => ThemeDialogs.showThemeSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.grid_view,
                    title: l10n.translate('list_style'),
                    subtitle: ListStyleDialogs.getListStyleName(SettingsManager().currentListStyle),
                    onTap: () => ListStyleDialogs.showListStyleSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsSwitchItem(
                    icon: Icons.layers_outlined,
                    title: l10n.translate('separate_list'),
                    subtitle: l10n.translate('separate_list_subtext'),
                    value: SettingsManager().separateListStyles,
                    onChanged: (val) => SettingsManager().setSeparateListStyles(val),
                    isLast: !SettingsManager().separateListStyles,
                  ),
                  if (SettingsManager().separateListStyles) ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.library_books_outlined,
                      title: l10n.translate('library_list_style'),
                      subtitle: ListStyleDialogs.getListStyleName(SettingsManager().libraryListStyle),
                      onTap: () => ListStyleDialogs.showLibraryListStyleSelectionDialog(context),
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.explore_outlined,
                      title: l10n.translate('browse_list_style'),
                      subtitle: ListStyleDialogs.getListStyleName(SettingsManager().browseListStyle),
                      onTap: () => ListStyleDialogs.showBrowseListStyleSelectionDialog(context),
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToContent(BuildContext context, LocalizationService l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) => SettingsCategoryScreen(
            title: l10n.translate('content'),
            children: [
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.star_outline,
                    title: l10n.translate('rating_step'),
                    subtitle: GeneralSettingsDialogs.getRatingSliderStepName(SettingsManager().ratingSliderStep),
                    onTap: () => GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(context),
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.tab,
                    title: l10n.translate('library_default'),
                    subtitle: GeneralSettingsDialogs.getLibraryTabName(SettingsManager().addLibraryDefaultTab),
                    onTap: () => GeneralSettingsDialogs.showAddLibraryDefaultTabSelectionDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.filter_alt_outlined,
                    title: l10n.translate('content_preferences'),
                    subtitle: ContentPreferencesDialogs.getContentPreferencesText(SettingsManager().contentPreferences),
                    onTap: () => ContentPreferencesDialogs.showContentPreferencesDialog(context),
                  ),
                  const SettingsDivider(),
                  SettingsSwitchItem(
                    icon: Icons.visibility_off_outlined,
                    title: l10n.translate('hide_library'),
                    subtitle: l10n.translate('hide_library_subtext'),
                    value: SettingsManager().hideLibrarySeriesInBrowse,
                    onChanged: (val) => SettingsManager().setHideLibrarySeriesInBrowse(val),
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAccount(BuildContext context, LocalizationService l10n, ProfileAuthService auth) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsCategoryScreen(
          title: l10n.translate('account'),
          children: [
            SettingsGroup(
              children: [
                SettingsItem(
                  icon: Icons.manage_accounts_outlined,
                  title: l10n.translate('account_settings'),
                  subtitle: l10n.translate('account_settings_subtext'),
                  onTap: () => launchUrl(Uri.parse('https://mangabaka.org/my/settings/profile'), mode: LaunchMode.externalApplication),
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
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pop(context); // Pop category screen
                        Navigator.pop(context); // Pop main settings screen
                      }
                    }
                  },
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAdvanced(BuildContext context, LocalizationService l10n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) => SettingsCategoryScreen(
            title: l10n.translate('advanced_settings'),
            children: [
              SettingsGroup(
                children: [
                  SettingsItem(
                    icon: Icons.restart_alt,
                    title: l10n.translate('redo_onboarding'),
                    subtitle: l10n.translate('redo_onboarding_subtitle'),
                    onTap: () async {
                       await SettingsManager().setHasCompletedOnboarding(false);
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Onboarding will show on next restart')),
                         );
                       }
                    },
                    isFirst: true,
                  ),
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.list_alt,
                    title: l10n.translate('logs'),
                    subtitle: l10n.translate('view_logs_subtitle'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsScreen())),
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
