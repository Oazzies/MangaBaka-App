import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/profile/developer/developer_tools.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/github_logo.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_customization.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_appearance_page.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/library/import/import_export_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_categories.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

part 'desktop_settings_nav_part.dart';
part 'desktop_settings_general_content_part.dart';
part 'desktop_settings_account_advanced_part.dart';
part 'desktop_settings_widgets_part.dart';

/// Settings as a real page on desktop: categories down the left,
/// inline desktop-native controls (dropdowns, switches, chips) on the right.
class DesktopSettingsScreen extends StatefulWidget {
  static final GlobalKey<DesktopSettingsScreenState> stateKey =
      GlobalKey<DesktopSettingsScreenState>();

  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => DesktopSettingsScreenState();
}

/// In the order the pages sit "down the page": switching to a later one
/// scrolls down to it, to an earlier one scrolls up.
enum _Category {
  appearance,
  general,
  lists,
  content,
  importExport,
  account,
  advanced,
  logs,
  translationCredits,
}

class DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  static const double _navWidth = 300;

  late final ProfileAuthService _auth;
  _Category _selected = _Category.general;

  @override
  void initState() {
    super.initState();
    _auth = getIt<ProfileAuthService>();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (!_auth.isLoggedIn && _selected == _Category.account) {
      _select(_Category.general);
    } else {
      setState(() {});
    }
  }

  /// The settings pages, by name, for tests that visit each one. Excludes
  /// [_Category.importExport], which never actually renders as a pane â€” its
  /// nav item navigates to [ImportExportScreen] instead.
  @visibleForTesting
  static List<String> get debugCategories => [
    for (final c in _Category.values)
      if (c != _Category.importExport) c.name,
  ];

  @visibleForTesting
  void debugSelectCategory(String name) =>
      _select(_Category.values.byName(name));

  void _select(_Category category) {
    if (category == _selected) return;
    setState(() {
      _selected = category;
    });
  }

  /// The nav entry that stands for the page on screen: Logs is opened from
  /// Advanced and has no entry of its own.
  _Category get _navSelected =>
      _selected == _Category.logs ? _Category.advanced : _selected;

  (IconData, Color, String, String) _describe(_Category c) => switch (c) {
    _Category.appearance => (
      Icons.palette_outlined,
      context.colors.accent,
      'appearance',
      'appearance_subtitle',
    ),
    _Category.general => (
      Icons.tune_rounded,
      context.colors.text,
      'general',
      'general_settings_subtitle',
    ),
    _Category.lists => (
      Icons.grid_view_rounded,
      context.colors.info,
      'list_customization',
      'list_customization_subtitle',
    ),
    _Category.content => (
      Icons.library_books_outlined,
      context.colors.star,
      'content',
      'library_settings_subtitle',
    ),
    _Category.importExport => (
      Icons.import_export_rounded,
      context.colors.info,
      'import_export_title',
      'import_export_subtitle',
    ),
    _Category.account => (
      Icons.person_outline_rounded,
      context.colors.accent,
      'account',
      'account_settings_subtitle',
    ),
    _Category.advanced => (
      Icons.code_rounded,
      context.colors.error,
      'advanced_settings',
      'advanced_settings_subtitle',
    ),
    _Category.translationCredits => (
      Icons.translate_rounded,
      context.colors.text,
      'translation_credits',
      'language_subtitle',
    ),
    _Category.logs => (
      Icons.list_alt,
      context.colors.error,
      'logs',
      'view_logs_subtitle',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        // Switching developer mode off while on its pages would strand the
        // user on a category the nav no longer lists.
        if (!SettingsManager().developerMode &&
            (_selected == _Category.advanced || _selected == _Category.logs)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _select(_Category.general);
          });
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopSidePanel(width: _navWidth, child: _nav(l10n)),
            Expanded(child: _pane(l10n)),
          ],
        );
      },
    );
  }

  Widget _nav(LocalizationService l10n) {
    final categories = [
      _Category.appearance,
      _Category.general,
      _Category.lists,
      _Category.content,
      _Category.importExport,
      if (_auth.isLoggedIn) _Category.account,
      // Developer Tools stay hidden until developer mode is switched on.
      if (SettingsManager().developerMode) _Category.advanced,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 20),
          child: Text(
            l10n.translate('settings').toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 30,
            ),
          ),
        ),
        for (final c in categories) _navItem(l10n, c),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            l10n.translate('information').toUpperCase(),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ),
        _link(
          leading: const Icon(
            Icons.discord,
            size: 18,
            color: FixedColors.discord,
          ),
          label: l10n.translate('discord'),
          external: true,
          onTap: () => launchUrl(
            Uri.parse('https://discord.gg/mangabaka'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        _link(
          leading: GithubLogo(size: 18, color: context.colors.text),
          label: l10n.translate('github'),
          external: true,
          onTap: () => launchUrl(
            Uri.parse('https://github.com/oazzies/MangaBaka-App'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        _link(
          leading: Icon(
            Icons.translate_rounded,
            size: 18,
            color: context.colors.text,
          ),
          label: l10n.translate('translation_credits'),
          selected: _selected == _Category.translationCredits,
          onTap: () => _select(_Category.translationCredits),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              DeveloperModeTapTarget(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/mangabaka512.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${AppConstants.appName} v${AppConstants.appVersion}',
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
