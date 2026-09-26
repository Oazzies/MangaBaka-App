import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';
import 'package:url_launcher/url_launcher.dart';

/// The top level of settings: one row per category, then the external links.
///
/// Shared by the portrait screen and the landscape dialog so the two cannot
/// drift apart on which categories exist or what order they are in.
List<Widget> buildSettingsGroups(
  BuildContext context,
  LocalizationService l10n,
  ProfileAuthService auth,
) {
  // The general category's subtitle is abbreviated on a phone, so the row
  // chooses its wording from the same breakpoint the category itself uses.
  final isSmallDevice = MediaQuery.sizeOf(context).width < 600;

  return [
    _category(
      icon: Icons.palette_outlined,
      title: l10n.translate('appearance'),
      subtitle: l10n.translate('appearance_subtitle'),
      onTap: () => SettingsCategories.appearance(context, l10n),
    ),
    const SizedBox(height: 16),
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
      subtitle: l10n.translate('import_export_subtitle'),
      onTap: () => SettingsCategories.importExport(context, l10n),
    ),
    const SizedBox(height: 16),
    // Account settings only exist for a signed-in user; there is nothing
    // behind this row when logged out.
    if (auth.isLoggedIn) ...[
      _category(
        icon: Icons.person_outline,
        title: l10n.translate('account'),
        subtitle: l10n.translate('account_settings_subtitle'),
        onTap: () => SettingsCategories.account(context, l10n, auth),
      ),
      const SizedBox(height: 16),
    ],
    _category(
      icon: Icons.code,
      title: l10n.translate('advanced_settings'),
      subtitle: l10n.translate('advanced_settings_subtitle'),
      onTap: () => SettingsCategories.advanced(context, l10n),
    ),
    const SizedBox(height: 32),
    SettingsGroup(
      children: [
        _externalLink(
          icon: Icons.discord,
          title: l10n.translate('discord'),
          url: 'https://discord.gg/mangabaka',
          isFirst: true,
        ),
        const SettingsDivider(),
        _externalLink(
          icon: Icons.code,
          title: l10n.translate('github'),
          url: 'https://github.com/oazzies/MangaBaka-App',
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

/// A category row. Each sits alone in its own group, which is what gives the
/// settings root its card-per-category rhythm.
Widget _category({
  required IconData icon,
  required String title,
  required String subtitle,
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

/// A row that leaves the app, marked with the standard external-link glyph.
Widget _externalLink({
  required IconData icon,
  required String title,
  required String url,
  bool isFirst = false,
}) {
  return SettingsItem(
    icon: icon,
    title: title,
    onTap: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    trailing: Builder(
      builder: (context) => Icon(
        Icons.open_in_new,
        color: context.colors.textMuted,
        size: 18,
      ),
    ),
    isFirst: isFirst,
  );
}

/// Wraps a built settings list so its cards fade and rise in sequence.
///
/// Spacers pass through untouched and do not consume an index, so the stagger
/// tracks visible cards rather than list positions.
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
