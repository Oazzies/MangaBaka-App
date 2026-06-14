import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_manager.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/screens/settings_category_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/theme_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/grid_column_dialogs.dart';

// ---------------------------------------------------------------------------
// Shared helper — shows a category as a dialog in landscape, pushes in portrait
// ---------------------------------------------------------------------------

void _showOrNavigate(
  BuildContext context, {
  required String title,
  Listenable? listenable,
  required List<Widget> Function(BuildContext) buildChildren,
}) {
  final isLandscape =
      MediaQuery.of(context).orientation == Orientation.landscape;

  Widget buildInner(BuildContext ctx) {
    final children = buildChildren(ctx);
    return isLandscape
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : SettingsCategoryScreen(title: title, children: children);
  }

  final content = listenable != null
      ? ListenableBuilder(
          listenable: listenable,
          builder: (ctx, _) => buildInner(ctx),
        )
      : Builder(builder: buildInner);

  if (isLandscape) {
    Navigator.pop(context);
    // Defer showing the new dialog until after the current one's pop animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootCtx = AppConstants.navigatorKey.currentContext;
      if (rootCtx != null) {
        SettingsCategoryScreen.showAsDialog(
          rootCtx,
          title: title,
          content: content,
          onBack: () =>
              SettingsScreen.show(AppConstants.navigatorKey.currentContext!),
        );
      }
    });
  } else {
    Navigator.push(context, MaterialPageRoute(builder: (_) => content));
  }
}

// ---------------------------------------------------------------------------
// Shared settings groups (used by both full-screen and dialog)
// ---------------------------------------------------------------------------

List<Widget> _buildSettingsGroups(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  return [
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
    SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.discord,
          title: l10n.translate('discord'),
          onTap: () => launchUrl(
            Uri.parse('https://discord.gg/mangabaka'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: AppConstants.textMutedColor,
            size: 18,
          ),
          isFirst: true,
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.code,
          title: l10n.translate('github'),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/oazzies/MangaBaka-App'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: AppConstants.textMutedColor,
            size: 18,
          ),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.info_outline,
          title: l10n.translate('translation_credits'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TranslationCreditsScreen(),
            ),
          ),
          isLast: true,
        ),
      ],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Navigation helpers
// ---------------------------------------------------------------------------

void _navigateToGeneral(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('general'),
    listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
    buildChildren: (ctx) {
      final l10n = LocalizationService();
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
                SettingsManager().defaultStartPage,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showAppStartPageSelectionDialog(ctx),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.translate,
              title: l10n.translate('title_language'),
              subtitle: GeneralSettingsDialogs.getTitleLanguageName(
                SettingsManager().defaultTitleLanguage,
              ),
              onTap: () =>
                  GeneralSettingsDialogs.showTitleLanguageSelectionDialog(ctx),
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
      ];
    },
  );
}

void _navigateToDisplay(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('display'),
    listenable: Listenable.merge([ThemeManager(), SettingsManager()]),
    buildChildren: (ctx) => [
      SettingsSectionHeader(title: l10n.translate('theme_colors')),
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.brightness_6_outlined,
            title: l10n.translate('theme_mode'),
            subtitle: ThemeDialogs.getThemeModeName(
              ThemeManager().currentThemeMode,
            ),
            onTap: () => ThemeDialogs.showThemeModeSelectionDialog(ctx),
            isFirst: true,
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.palette_outlined,
            title: l10n.translate('app_theme'),
            subtitle: ThemeDialogs.getThemeName(ThemeManager().currentTheme),
            onTap: () => ThemeDialogs.showThemeSelectionDialog(ctx),
            isLast: true,
          ),
        ],
      ),
      const SizedBox(height: 16),
      SettingsSectionHeader(title: l10n.translate('layout_columns')),
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.grid_view,
            title: l10n.translate('list_style'),
            subtitle: ListStyleDialogs.getListStyleName(
              SettingsManager().currentListStyle,
            ),
            onTap: () => ListStyleDialogs.showListStyleSelectionDialog(ctx),
            isFirst: true,
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.view_column_outlined,
            title: l10n.translate('grid_columns'),
            subtitle: GridColumnDialogs.getGridColumnLabel(
              SettingsManager().gridColumnCount,
            ),
            onTap: () => GridColumnDialogs.showGridColumnCountDialog(ctx),
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.grid_on_outlined,
            title: l10n.translate('separate_grid_columns'),
            subtitle: l10n.translate('separate_grid_columns_subtitle'),
            value: SettingsManager().separateGridColumnCounts,
            onChanged: (val) =>
                SettingsManager().setSeparateGridColumnCounts(val),
            isLast: !SettingsManager().separateGridColumnCounts,
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (SettingsManager().separateGridColumnCounts) ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.library_books_outlined,
                      title: l10n.translate('library_grid_columns'),
                      subtitle: GridColumnDialogs.getGridColumnLabel(
                        SettingsManager().libraryGridColumnCount,
                      ),
                      onTap: () =>
                          GridColumnDialogs.showLibraryGridColumnCountDialog(
                            ctx,
                          ),
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.explore_outlined,
                      title: l10n.translate('browse_grid_columns'),
                      subtitle: GridColumnDialogs.getGridColumnLabel(
                        SettingsManager().browseGridColumnCount,
                      ),
                      onTap: () =>
                          GridColumnDialogs.showBrowseGridColumnCountDialog(
                            ctx,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.stay_primary_landscape_outlined,
            title: l10n.translate('landscape_appbar_position'),
            subtitle: GeneralSettingsDialogs.getLandscapeAppBarPositionName(
              SettingsManager().landscapeAppBarPosition,
            ),
            onTap: () =>
                GeneralSettingsDialogs.showLandscapeAppBarPositionDialog(ctx),
            isLast: true,
          ),
        ],
      ),
      const SizedBox(height: 16),
      SettingsSectionHeader(title: l10n.translate('progress_tracking')),
      SettingsGroup(
        children: [
          SettingsSwitchItem(
            icon: Icons.analytics_outlined,
            title: l10n.translate('show_library_progress'),
            subtitle: l10n.translate('show_library_progress_subtitle'),
            value: SettingsManager().showLibraryProgress,
            onChanged: (val) => SettingsManager().setShowLibraryProgress(val),
            isFirst: true,
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (SettingsManager().showLibraryProgress) ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.menu_book_outlined,
                      title: l10n.translate('library_progress_type'),
                      subtitle: GeneralSettingsDialogs.getLibraryProgressTypeName(
                        SettingsManager().libraryProgressType,
                      ),
                      onTap: () => GeneralSettingsDialogs
                          .showLibraryProgressTypeSelectionDialog(ctx),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.hourglass_empty,
            title: l10n.translate('show_remaining_progress'),
            subtitle: l10n.translate('show_remaining_progress_subtitle'),
            value: SettingsManager().showRemainingProgress,
            onChanged: (val) =>
                SettingsManager().setShowRemainingProgress(val),
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.add_circle_outline,
            title: l10n.translate('show_quick_progress'),
            subtitle: l10n.translate('show_quick_progress_subtitle'),
            value: SettingsManager().showQuickProgress,
            onChanged: (val) => SettingsManager().setShowQuickProgress(val),
            isLast: true,
          ),
        ],
      ),
      const SizedBox(height: 16),
      SettingsSectionHeader(title: l10n.translate('list_customization')),
      SettingsGroup(
        children: [
          SettingsSwitchItem(
            icon: Icons.layers_outlined,
            title: l10n.translate('separate_list'),
            subtitle: l10n.translate('separate_list_subtext'),
            value: SettingsManager().separateListStyles,
            onChanged: (val) => SettingsManager().setSeparateListStyles(val),
            isFirst: true,
            isLast: false,
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (SettingsManager().separateListStyles) ...[
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.library_books_outlined,
                      title: l10n.translate('library_list_style'),
                      subtitle: ListStyleDialogs.getListStyleName(
                        SettingsManager().libraryListStyle,
                      ),
                      onTap: () =>
                          ListStyleDialogs.showLibraryListStyleSelectionDialog(
                            ctx,
                          ),
                    ),
                    const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.explore_outlined,
                      title: l10n.translate('browse_list_style'),
                      subtitle: ListStyleDialogs.getListStyleName(
                        SettingsManager().browseListStyle,
                      ),
                      onTap: () =>
                          ListStyleDialogs.showBrowseListStyleSelectionDialog(
                            ctx,
                          ),
                      isLast: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.tag,
            title: l10n.translate('show_library_tab_counts'),
            subtitle: l10n.translate('show_library_tab_counts_subtitle'),
            value: SettingsManager().showLibraryTabCounts,
            onChanged: (val) => SettingsManager().setShowLibraryTabCounts(val),
            isLast: true,
          ),
        ],
      ),
    ],
  );
}

void _navigateToContent(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('content'),
    listenable: SettingsManager(),
    buildChildren: (ctx) => [
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.star_outline,
            title: l10n.translate('rating_step'),
            subtitle: GeneralSettingsDialogs.getRatingSliderStepName(
              SettingsManager().ratingSliderStep,
            ),
            onTap: () =>
                GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(ctx),
            isFirst: true,
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.tab,
            title: l10n.translate('library_default'),
            subtitle: GeneralSettingsDialogs.getLibraryTabName(
              SettingsManager().addLibraryDefaultTab,
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
              SettingsManager().contentPreferences,
            ),
            onTap: () =>
                ContentPreferencesDialogs.showContentPreferencesDialog(ctx),
          ),
          const SettingsDivider(),
          SettingsSwitchItem(
            icon: Icons.visibility_off_outlined,
            title: l10n.translate('hide_library'),
            subtitle: l10n.translate('hide_library_subtext'),
            value: SettingsManager().hideLibrarySeriesInBrowse,
            onChanged: (val) =>
                SettingsManager().setHideLibrarySeriesInBrowse(val),
            isLast: true,
          ),
        ],
      ),
    ],
  );
}

void _navigateToAccount(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  _showOrNavigate(
    context,
    title: l10n.translate('account'),
    buildChildren: (ctx) => [
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
            trailing: Icon(
              Icons.open_in_new,
              color: AppConstants.textMutedColor,
              size: 20,
            ),
            isFirst: true,
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.logout_outlined,
            title: l10n.translate('logout'),
            subtitle: l10n.translate('logout_subtext'),
            onTap: () async {
              final shouldLogout =
                  await LogoutDialog.showLogoutConfirmationDialog(ctx);
              if (shouldLogout == true) {
                try {
                  await auth.logout();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                  return;
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx); // Close account dialog/screen
                  Navigator.pop(ctx); // Close main settings dialog/screen
                }
              }
            },
            isLast: true,
          ),
        ],
      ),
    ],
  );
}

void _navigateToAdvanced(BuildContext context, LocalizationService l10n) {
  _showOrNavigate(
    context,
    title: l10n.translate('advanced_settings'),
    listenable: SettingsManager(),
    buildChildren: (ctx) => [
      SettingsGroup(
        children: [
          SettingsItem(
            icon: Icons.restart_alt,
            title: l10n.translate('redo_onboarding'),
            subtitle: l10n.translate('redo_onboarding_subtitle'),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (context) => const OnboardingScreen(isRedoing: true),
              ),
            ),
            isFirst: true,
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.list_alt,
            title: l10n.translate('logs'),
            subtitle: l10n.translate('view_logs_subtitle'),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (context) => const LogsScreen()),
            ),
            isLast: true,
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Full-screen settings screen
// ---------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const _SettingsDialog(),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

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
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
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
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.largeRadius,
                          ),
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
                ..._buildSettingsGroups(context, l10n, auth),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape dialog
// ---------------------------------------------------------------------------

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

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
        final maxHeight = MediaQuery.of(context).size.height - 64;

        return Dialog(
          backgroundColor: AppConstants.primaryBackground,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Text(
                        l10n.translate('settings'),
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppConstants.textMutedColor,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppConstants.borderColor),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppConstants.horizontalPadding,
                      right: AppConstants.horizontalPadding,
                      top: 16,
                      bottom: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildSettingsGroups(context, l10n, auth),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
