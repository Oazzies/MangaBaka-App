import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/github_logo.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:url_launcher/url_launcher.dart';

List<Widget> buildSettingsGroups(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  // Must match SettingsCategories._smallDeviceWidth, the breakpoint the general category uses.
  final isSmallDevice = MediaQuery.sizeOf(context).width < 600;

  return [
    _category(
      icon: Icons.settings_outlined,
      title: l10n.translate('general'),
      subtitle: l10n.translate(
        isSmallDevice
            ? 'general_settings_subtitle_mobile'
            : 'general_settings_subtitle',
      ),
      onTap: () => SettingsCategories.general(context, l10n),
    ),
    const SizedBox(height: 16),
    _category(
      icon: Icons.palette_outlined,
      title: l10n.translate('appearance'),
      subtitle: l10n.translate('appearance_subtitle'),
      onTap: () => SettingsCategories.appearance(context, l10n),
    ),
    const SizedBox(height: 16),
    _category(
      icon: Icons.grid_view,
      title: l10n.translate('list_customization'),
      subtitle: l10n.translate('list_customization_subtitle'),
      onTap: () => SettingsCategories.listCustomization(context, l10n),
    ),
    const SizedBox(height: 16),
    _category(
      icon: Icons.library_books_outlined,
      title: l10n.translate('content'),
      subtitle: l10n.translate('library_settings_subtitle'),
      onTap: () => SettingsCategories.content(context, l10n),
    ),
    const SizedBox(height: 16),
    _category(
      icon: Icons.import_export_rounded,
      title: l10n.translate('import_export_title'),
      onTap: () => SettingsCategories.importExport(context, l10n),
    ),
    const SizedBox(height: 16),
    if (auth.isLoggedIn) ...[
      _category(
        icon: Icons.person_outline,
        title: l10n.translate('account'),
        onTap: () => SettingsCategories.account(context, l10n, auth),
      ),
      const SizedBox(height: 16),
    ],
    if (SettingsManager().developerMode) ...[
      _category(
        icon: Icons.code,
        title: l10n.translate('advanced_settings'),
        subtitle: l10n.translate('advanced_settings_subtitle'),
        onTap: () => SettingsCategories.advanced(context, l10n),
      ),
    ],
    const SizedBox(height: 32),
    SettingsGroup(
      children: [
        _externalLink(
          leading: const Icon(
            Icons.discord,
            size: 20,
            color: FixedColors.discord,
          ),
          title: l10n.translate('discord'),
          url: 'https://discord.gg/mangabaka',
          isFirst: true,
        ),
        const SettingsDivider(),
        Builder(
          builder: (context) => _externalLink(
            leading: GithubLogo(size: 20, color: context.colors.text),
            title: l10n.translate('github'),
            url: 'https://github.com/oazzies/MangaBaka-App',
          ),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.info_outline,
          title: l10n.translate('translation_credits'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TranslationCreditsScreen()),
          ),
          isLast: true,
        ),
      ],
    ),
  ];
}

Widget _category({
  required IconData icon,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return SettingsGroup(
    children: [
      SettingsCategoryRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    ],
  );
}

Widget _externalLink({
  required Widget leading,
  required String title,
  required String url,
  bool isFirst = false,
}) {
  return SettingsItem(
    leadingIcon: leading,
    title: title,
    onTap: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    trailing: Builder(
      builder: (context) =>
          Icon(
            Icons.open_in_new_rounded,
            color: context.colors.textMuted,
            size: 18,
          ),
    ),
    isFirst: isFirst,
  );
}

List<Widget> staggered(List<Widget> children) {
  var index = 0;
  return [
    for (final child in children)
      if (child is SizedBox)
        child
      else
        MbEntrance(index: index++, child: child),
  ];
}
