part of 'desktop_settings_screen.dart';

extension _DesktopSettingsAccountAdvanced on DesktopSettingsScreenState {
  Widget _buildAccount(LocalizationService l10n) {
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DesktopSettingRow(
            icon: Icons.manage_accounts_outlined,
            title: l10n.translate('account_settings'),
            subtitle: l10n.translate('account_settings_subtext'),
            control: DesktopPillButton(
              label: l10n.translate('account_settings'),
              icon: Icons.open_in_new,
              onPressed: () => launchUrl(
                Uri.parse('https://mangabaka.org/my/settings/profile'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.logout_outlined,
            title: l10n.translate('logout'),
            subtitle: l10n.translate('logout_subtext'),
            control: DesktopPillButton(
              label: l10n.translate('logout'),
              icon: Icons.logout_rounded,
              danger: true,
              onPressed: () async {
                final confirmed =
                    await LogoutDialog.showLogoutConfirmationDialog(context);
                if (confirmed != true) return;
                try {
                  await _auth.logout();
                } on AppException {
                  // logout() logs the cause and wraps it in AuthException.
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      LocalizationService().translate('logout_failed'),
                      isError: true,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanced(LocalizationService l10n) {
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DesktopSettingRow(
            icon: Icons.restart_alt,
            title: l10n.translate('redo_onboarding'),
            subtitle: l10n.translate('redo_onboarding_subtitle'),
            control: DesktopPillButton(
              label: l10n.translate('redo_onboarding'),
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(isRedoing: true),
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.list_alt,
            title: l10n.translate('logs'),
            subtitle: l10n.translate('view_logs_subtitle'),
            control: DesktopPillButton(
              label: l10n.translate('logs'),
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _select(_Category.logs),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.system_update_rounded,
            title: l10n.translate('trigger_update_widget'),
            subtitle: l10n.translate('trigger_update_widget_subtitle'),
            control: DesktopPillButton(
              label: l10n.translate('trigger_update_widget'),
              icon: Icons.system_update_rounded,
              onPressed: () =>
                  UpdateDialog.show(context, SettingsCategories.debugRelease),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.notifications_active_outlined,
            title: l10n.translate('preview_toasts'),
            subtitle: l10n.translate('preview_toasts_subtitle'),
            control: DesktopPillButton(
              label: l10n.translate('preview_toasts'),
              icon: Icons.notifications_active_outlined,
              onPressed: () => showToastPreviewPicker(context),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.web_asset_rounded,
            title: l10n.translate('preview_dialogs'),
            subtitle: l10n.translate('preview_dialogs_subtitle'),
            control: DesktopPillButton(
              label: l10n.translate('preview_dialogs'),
              icon: Icons.web_asset_rounded,
              onPressed: () => showDialogPreviewPicker(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationCredits(LocalizationService l10n) {
    final languages = l10n.getLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final lang in languages) ...[
          DesktopCard(
            showBorder: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lang['name'] as String,
                      style: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${lang['code']})',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final t in (lang['translators'] as List<String>))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(
                            AppConstants.pillRadius,
                          ),
                        ),
                        child: Text(
                          t,
                          style: AppTypography.sans(
                            color: context.colors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
