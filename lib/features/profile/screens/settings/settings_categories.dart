import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/appearance/screens/appearance_settings.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_service.dart';
import 'package:mangabaka_app/features/library/import/import_export_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_account_advanced.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_navigation.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_settings.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

/// The contents of each settings category.
///
/// Every entry point here hands its rows to [showOrNavigate], which decides
/// between pushing a screen and pushing a page onto the landscape dialog. The
/// categories are grouped in this one file because they are all the same kind
/// of thing — a list of [SettingsItem]s — and splitting them further would
/// leave five files of a dozen lines each.
class SettingsCategories {
  SettingsCategories._();

  /// Below this width the general category hides the tooltip toggle: tooltips
  /// are a pointer affordance and there is no hover on a phone.
  static const double _smallDeviceWidth = 600;

  /// Fake release fed to [UpdateDialog] from the "trigger update widget" row —
  /// styling/QA only, never a real check against GitHub.
  static const AppRelease debugRelease = AppRelease(
    tagName: 'v9.9.9',
    name: 'MangaBaka 9.9.9',
    body:
        'This is placeholder release-note text used to preview the update '
        'dialog. It exists only to check the dialog\'s styling and layout — '
        'nothing was actually released.',
    htmlUrl: '',
    draft: false,
    prerelease: false,
    assets: [],
  );

  static void general(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
      context,
      title: l10n.translate('general'),
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      buildChildren: (ctx) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        final isSmallDevice = MediaQuery.sizeOf(ctx).width < _smallDeviceWidth;

        return [
          SettingsGroup(
            children: [
              SettingsItem(
                icon: Icons.language,
                title: l10n.translate('language'),
                subtitle: GeneralSettingsDialogs.getLanguageName(
                  l10n.currentLanguage,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showLanguageSelectionDialog(ctx),
                isFirst: true,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.start,
                title: l10n.translate('start_page'),
                subtitle: GeneralSettingsDialogs.getAppStartPageName(
                  settings.defaultStartPage,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showAppStartPageSelectionDialog(ctx),
              ),
              // The desktop shell has its own sidebar; where the phone and
              // tablet bar sits does not apply to it.
              if (!DesktopLayout.isActive(ctx)) ...[
                const SettingsDivider(),
                SettingsItem(
                  icon: Icons.stay_primary_landscape_outlined,
                  title: l10n.translate('landscape_appbar_position'),
                  subtitle:
                      GeneralSettingsDialogs.getLandscapeAppBarPositionName(
                        settings.landscapeAppBarPosition,
                      ),
                  onTap: () =>
                      GeneralSettingsDialogs.showLandscapeAppBarPositionDialog(
                        ctx,
                      ),
                ),
              ],
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.translate,
                title: l10n.translate('title_language'),
                subtitle: GeneralSettingsDialogs.getTitleLanguageName(
                  settings.defaultTitleLanguage,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showTitleLanguageSelectionDialog(
                      ctx,
                    ),
              ),
              if (!isSmallDevice) ...[
                const SettingsDivider(),
                SettingsSwitchItem(
                  icon: Icons.help_outline,
                  title: l10n.translate('show_tooltips'),
                  subtitle: l10n.translate('show_tooltips_subtext'),
                  value: settings.showTooltips,
                  onChanged: settings.setShowTooltips,
                ),
              ],
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.search,
                title: l10n.translate('auto_suggest_browse'),
                subtitle: l10n.translate('auto_suggest_browse_subtitle'),
                value: settings.autoSuggestBrowse,
                onChanged: settings.setAutoSuggestBrowse,
              ),
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.keyboard_alt_outlined,
                title: l10n.translate('auto_focus_browse_search'),
                subtitle: l10n.translate('auto_focus_browse_search_subtitle'),
                value: settings.autoFocusBrowseSearch,
                onChanged: settings.setAutoFocusBrowseSearch,
              ),
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.local_library_outlined,
                title: l10n.translate('auto_suggest_library'),
                subtitle: l10n.translate('auto_suggest_library_subtitle'),
                value: settings.autoSuggestLibrary,
                onChanged: settings.setAutoSuggestLibrary,
              ),
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.link_rounded,
                title: l10n.translate('open_links'),
                subtitle: l10n.translate(DeepLinkService.subtextKey),
                value: settings.openLinksInApp,
                onChanged: settings.setOpenLinksInApp,
                isLast: true,
              ),
            ],
          ),
        ];
      },
    );
  }

  /// Themes, mode and accent. The page listens to the theme controller
  /// itself, so no listenable is threaded through here.
  static void appearance(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
      context,
      title: l10n.translate('appearance'),
      buildChildren: (_) => const [AppearanceSettings()],
    );
  }

  static void listCustomization(
    BuildContext context,
    LocalizationService l10n,
  ) {
    showOrNavigate(
      context,
      title: l10n.translate('list_customization'),
      listenable: SettingsManager(),
      buildChildren: (_) => [ListCustomizationSettings(l10n: l10n)],
    );
  }

  static void content(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
      context,
      title: l10n.translate('content'),
      listenable: SettingsManager(),
      buildChildren: (ctx) {
        final settings = SettingsManager();
        return [
          SettingsGroup(
            children: [
              SettingsItem(
                icon: Icons.star_outline,
                title: l10n.translate('rating_step'),
                subtitle: GeneralSettingsDialogs.getRatingSliderStepName(
                  settings.ratingSliderStep,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(
                      ctx,
                    ),
                isFirst: true,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.tab,
                title: l10n.translate('library_default'),
                subtitle: GeneralSettingsDialogs.getLibraryTabName(
                  settings.addLibraryDefaultTab,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showAddLibraryDefaultTabSelectionDialog(
                      ctx,
                    ),
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.filter_alt_outlined,
                title: l10n.translate('content_preferences'),
                subtitle: ContentPreferencesDialogs.getContentPreferencesText(
                  settings.contentPreferences,
                ),
                onTap: () =>
                    ContentPreferencesDialogs.showContentPreferencesDialog(ctx),
              ),
              const SettingsDivider(),
              SettingsSwitchItem(
                icon: Icons.visibility_off_outlined,
                title: l10n.translate('hide_library'),
                subtitle: l10n.translate('hide_library_subtext'),
                value: settings.hideLibrarySeriesInBrowse,
                onChanged: settings.setHideLibrarySeriesInBrowse,
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.check_circle_outline,
                title: l10n.translate('auto_complete_chapters'),
                subtitle:
                    GeneralSettingsDialogs.getAutoCompleteProgressModeName(
                      settings.autoCompleteChapterProgress,
                    ),
                onTap: () =>
                    GeneralSettingsDialogs.showAutoCompleteProgressSelectionDialog(
                      ctx,
                    ),
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.task_alt_outlined,
                title: l10n.translate('auto_complete_series_status'),
                subtitle:
                    GeneralSettingsDialogs.getAutoCompleteProgressModeName(
                      settings.autoCompleteSeriesStatus,
                    ),
                onTap: () =>
                    GeneralSettingsDialogs.showAutoCompleteSeriesStatusSelectionDialog(
                      ctx,
                    ),
              ),
              const SettingsDivider(),
              SettingsItem(
                icon: Icons.exposure_plus_1_rounded,
                title: l10n.translate('progress_overflow'),
                subtitle: GeneralSettingsDialogs.getProgressOverflowModeName(
                  settings.progressOverflow,
                ),
                onTap: () =>
                    GeneralSettingsDialogs.showProgressOverflowSelectionDialog(
                      ctx,
                    ),
                isLast: true,
              ),
            ],
          ),
        ];
      },
    );
  }

  /// Unlike the other categories, this isn't a list of settings — it's the
  /// import/export hub screen itself, pushed straight away.
  static void importExport(BuildContext context, LocalizationService l10n) =>
      ImportExportScreen.open(context);

  static void account(
    BuildContext context,
    LocalizationService l10n,
    ProfileAuthService auth,
  ) => SettingsAccountAdvanced.account(context, l10n, auth);

  static void advanced(BuildContext context, LocalizationService l10n) =>
      SettingsAccountAdvanced.advanced(context, l10n);
}
