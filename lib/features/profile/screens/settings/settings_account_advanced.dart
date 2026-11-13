import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/developer/developer_tools.dart';
import 'package:mangabaka_app/features/profile/screens/logs_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_navigation.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Account and advanced settings category builders extracted from
/// [SettingsCategories] to keep each file focused and under 300 lines.
class SettingsAccountAdvanced {
  SettingsAccountAdvanced._();

  static void account(
    BuildContext context,
    LocalizationService l10n,
    ProfileAuthService auth,
  ) {
    showOrNavigate(
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
                color: ctx.colors.textMuted,
                size: 20,
              ),
              isFirst: true,
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.logout_outlined,
              title: l10n.translate('logout'),
              subtitle: l10n.translate('logout_subtext'),
              onTap: () => _confirmAndLogout(ctx, auth),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _confirmAndLogout(
    BuildContext context,
    ProfileAuthService auth,
  ) async {
    final confirmed = await LogoutDialog.showLogoutConfirmationDialog(context);
    if (confirmed != true) return;

    try {
      await auth.logout();
    } on AppException {
      // logout() logs the cause and wraps every failure in AuthException.
      if (context.mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('logout_failed'),
          isError: true,
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (InlineSettingsHost.maybeOf(context) != null) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  static void advanced(BuildContext context, LocalizationService l10n) {
    showOrNavigate(
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
              onTap: () => Navigator.of(ctx, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(isRedoing: true),
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
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.system_update_rounded,
              title: l10n.translate('trigger_update_widget'),
              subtitle: l10n.translate('trigger_update_widget_subtitle'),
              onTap: () => UpdateDialog.show(
                ctx,
                SettingsCategories.debugRelease,
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.notifications_active_outlined,
              title: l10n.translate('preview_toasts'),
              subtitle: l10n.translate('preview_toasts_subtitle'),
              onTap: () => showToastPreviewPicker(ctx),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.web_asset_rounded,
              title: l10n.translate('preview_dialogs'),
              subtitle: l10n.translate('preview_dialogs_subtitle'),
              onTap: () => showDialogPreviewPicker(ctx),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}
