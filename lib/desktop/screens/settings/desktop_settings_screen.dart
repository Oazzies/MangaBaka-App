import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:mangabaka_app/features/navigation/screens/onboarding_screen.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
  account,
  advanced,
  logs,
  translationCredits,
}

class DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  static const double _navWidth = 300;

  /// How long the pages take to scroll past each other.
  static const Duration _scrollDuration = Duration(milliseconds: 460);

  late final ProfileAuthService _auth;
  _Category _selected = _Category.general;

  /// +1 when the last switch moved down the page, -1 when it moved up.
  int _direction = 1;

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

  void _select(_Category category) {
    if (category == _selected) return;
    setState(() {
      _direction = category.index > _selected.index ? 1 : -1;
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
      if (_auth.isLoggedIn) _Category.account,
      _Category.advanced,
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
              Image.asset('assets/mangabaka512.png', width: 22, height: 22),
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
    );
  }

  Widget _navItem(LocalizationService l10n, _Category c) {
    final (icon, _, titleKey, subtitleKey) = _describe(c);
    final selected = c == _navSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DesktopHoverSurface(
        onTap: () => _select(c),
        selected: selected,
        selectedColor: context.colors.surfaceRaised,
        hoverColor: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate(titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.translate(subtitleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _link({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
    bool external = false,
    bool selected = false,
  }) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: selected,
      selectedColor: context.colors.surfaceRaised,
      hoverColor: context.colors.surface,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 18, height: 18, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (external)
            Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: context.colors.textMuted,
            ),
        ],
      ),
    );
  }

  // ─── The page area ──────────────────────────────────────────────────────────

  /// Every category is a page of its own, stacked in a column: General on top,
  /// then List customization, Content and so on down. Switching does not swap
  /// the content in place — it scrolls to it, the page you leave sliding off
  /// one edge as the next slides in from the other. The pages are not really
  /// one scrollable, so this is purely the transition.
  Widget _pane(LocalizationService l10n) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: _scrollDuration,
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        // Both pages fill the pane, so a slide of one page-height is a slide
        // of exactly the pane.
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: _scrollTransition,
        child: KeyedSubtree(
          key: ValueKey(_selected),
          child: _page(_selected, l10n),
        ),
      ),
    );
  }

  Widget _scrollTransition(Widget child, Animation<double> animation) {
    final entering = child.key == ValueKey(_selected);
    // Moving down the page: the new page comes up from below while the old one
    // leaves through the top. Moving up is the mirror image.
    final from = Offset(0, (entering ? _direction : -_direction).toDouble());
    return SlideTransition(
      position: Tween<Offset>(begin: from, end: Offset.zero).animate(animation),
      child: child,
    );
  }

  Widget _page(_Category category, LocalizationService l10n) {
    final (_, _, titleKey, subtitleKey) = _describe(category);

    // Logs are one long scrolling list of their own, so they take the whole
    // pane instead of sitting in the capped, page-scrolling column.
    if (category == _Category.logs) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(48, 36, 48, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pageHeader(
              l10n,
              titleKey,
              subtitleKey,
              leading: DesktopIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.translate('back'),
                filled: true,
                onPressed: () => _select(_Category.advanced),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _DesktopLogsView(l10n: l10n)),
          ],
        ),
      );
    }

    // The list page splits into two columns, which wants more than the reading
    // width the text-and-toggle pages are held to.
    final maxWidth =
        category == _Category.lists || category == _Category.appearance
        ? DesktopTokens.maxPageWidth * 0.75
        : DesktopTokens.readableWidth;

    return _ScrollPage(
      padding: const EdgeInsets.fromLTRB(48, 10, 48, 48),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(l10n, titleKey, subtitleKey),
              const SizedBox(height: 24),
              _buildCategoryContent(category, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageHeader(
    LocalizationService l10n,
    String titleKey,
    String subtitleKey, {
    Widget? leading,
  }) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate(titleKey).toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.translate(subtitleKey),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );

    if (leading == null) return text;
    return Row(
      children: [
        leading,
        const SizedBox(width: 14),
        Expanded(child: text),
      ],
    );
  }

  Widget _buildCategoryContent(_Category category, LocalizationService l10n) {
    return switch (category) {
      _Category.appearance => const DesktopAppearancePage(),
      _Category.general => _buildGeneral(l10n),
      _Category.lists => DesktopListCustomization(l10n: l10n),
      _Category.content => _buildContent(l10n),
      _Category.account => _buildAccount(l10n),
      _Category.advanced => _buildAdvanced(l10n),
      _Category.translationCredits => _buildTranslationCredits(l10n),
      _Category.logs => const SizedBox.shrink(), // handled full-pane in _page
    };
  }

  // ─── General Category ───────────────────────────────────────────────────────
  Widget _buildGeneral(LocalizationService l10n) {
    final settings = SettingsManager();
    final languages = l10n.getLanguages();

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DesktopSettingRow(
            icon: Icons.language,
            title: l10n.translate('language'),
            subtitle: l10n.translate('language_subtitle'),
            control: DesktopMenuButton<String>(
              valueLabel: GeneralSettingsDialogs.getLanguageName(
                l10n.currentLanguage,
              ),
              items: languages
                  .map((l) => (l['code'] as String, l['native_name'] as String))
                  .toList(),
              selected: l10n.currentLanguage,
              onSelected: (code) => l10n.setLanguage(code),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.start,
            title: l10n.translate('start_page'),
            subtitle: l10n.translate('start_page_subtitle'),
            control: DesktopMenuButton<AppStartPage>(
              valueLabel: GeneralSettingsDialogs.getAppStartPageName(
                settings.defaultStartPage,
              ),
              items: AppStartPage.values
                  .map(
                    (p) => (p, GeneralSettingsDialogs.getAppStartPageName(p)),
                  )
                  .toList(),
              selected: settings.defaultStartPage,
              onSelected: (p) => settings.setDefaultStartPage(p),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.translate,
            title: l10n.translate('title_language'),
            subtitle: l10n.translate('title_language_subtitle'),
            control: DesktopMenuButton<TitleLanguage>(
              valueLabel: GeneralSettingsDialogs.getTitleLanguageName(
                settings.defaultTitleLanguage,
              ),
              items: TitleLanguage.values
                  .map(
                    (t) => (t, GeneralSettingsDialogs.getTitleLanguageName(t)),
                  )
                  .toList(),
              selected: settings.defaultTitleLanguage,
              onSelected: (t) => settings.setDefaultTitleLanguage(t),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.help_outline,
            title: l10n.translate('show_tooltips'),
            subtitle: l10n.translate('show_tooltips_subtext'),
            control: Switch(
              value: settings.showTooltips,
              onChanged: settings.setShowTooltips,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.search,
            title: l10n.translate('auto_suggest_browse'),
            subtitle: l10n.translate('auto_suggest_browse_subtitle'),
            control: Switch(
              value: settings.autoSuggestBrowse,
              onChanged: settings.setAutoSuggestBrowse,
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.local_library_outlined,
            title: l10n.translate('auto_suggest_library'),
            subtitle: l10n.translate('auto_suggest_library_subtitle'),
            control: Switch(
              value: settings.autoSuggestLibrary,
              onChanged: settings.setAutoSuggestLibrary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Content Category ───────────────────────────────────────────────────────
  Widget _buildContent(LocalizationService l10n) {
    final settings = SettingsManager();
    final defaultTabs = const [
      'reading',
      'paused',
      'completed',
      'plan_to_read',
      'dropped',
      'rereading',
      'considering',
    ];
    final ratingSteps = RatingSliderStep.values;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesktopSettingRow(
            icon: Icons.star_outline,
            title: l10n.translate('rating_step'),
            subtitle: l10n.translate('rating_step_subtitle'),
            control: DesktopMenuButton<RatingSliderStep>(
              valueLabel: GeneralSettingsDialogs.getRatingSliderStepName(
                settings.ratingSliderStep,
              ),
              items: ratingSteps
                  .map(
                    (s) =>
                        (s, GeneralSettingsDialogs.getRatingSliderStepName(s)),
                  )
                  .toList(),
              selected: settings.ratingSliderStep,
              onSelected: (s) => settings.setRatingSliderStep(s),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.tab,
            title: l10n.translate('library_default'),
            subtitle: l10n.translate('library_default_subtitle'),
            control: DesktopMenuButton<String>(
              valueLabel: GeneralSettingsDialogs.getLibraryTabName(
                settings.addLibraryDefaultTab,
              ),
              items: defaultTabs
                  .map((t) => (t, GeneralSettingsDialogs.getLibraryTabName(t)))
                  .toList(),
              selected: settings.addLibraryDefaultTab,
              onSelected: (t) => settings.setAddLibraryDefaultTab(t),
            ),
          ),
          const Divider(height: 24),
          DesktopSettingRow(
            icon: Icons.visibility_off_outlined,
            title: l10n.translate('hide_library'),
            subtitle: l10n.translate('hide_library_subtext'),
            control: Switch(
              value: settings.hideLibrarySeriesInBrowse,
              onChanged: settings.setHideLibrarySeriesInBrowse,
            ),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: context.colors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('content_preferences').toUpperCase(),
                      style: AppTypography.display(
                        color: context.colors.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.translate('content_preferences_subtitle'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final rating in _contentRatings)
                      _ContentRatingRow(rating: rating, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _contentRatings = [
    'safe',
    'suggestive',
    'erotica',
    'pornographic',
  ];

  // ─── Account Category ───────────────────────────────────────────────────────
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
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.show(
                      context,
                      'Logout failed: $e',
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

  // ─── Advanced Category ──────────────────────────────────────────────────────
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

/// A page that scrolls on its own, with its own controller.
///
/// Two pages are on screen at once while the settings pages scroll past each
/// other, and two scroll views must not share the ambient primary controller.
class _ScrollPage extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _ScrollPage({required this.padding, required this.child});

  @override
  State<_ScrollPage> createState() => _ScrollPageState();
}

class _ScrollPageState extends State<_ScrollPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: ListView(
        controller: _controller,
        padding: widget.padding,
        children: [widget.child],
      ),
    );
  }
}

/// One content rating: whether it is shown at all and, once shown, whether its
/// covers are blurred.
///
/// The blur choice only means something for a rating that is on, so it appears
/// only then — the same rule the phone's sheet follows.
class _ContentRatingRow extends StatelessWidget {
  final String rating;
  final LocalizationService l10n;

  const _ContentRatingRow({required this.rating, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final selected = settings.contentPreferences.contains(rating);
    final blurred = settings.blurredContentRatings.contains(rating);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DesktopHoverSurface(
        onTap: () => _toggleShown(settings, selected),
        idleColor: context.colors.surfaceRaised,
        hoverColor: context.colors.border,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(selected),
                size: 22,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate(rating).toUpperCase(),
                style: AppTypography.display(
                  color: selected
                      ? context.colors.text
                      : context.colors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            if (selected) ...[
              Icon(
                blurred ? Icons.blur_on : Icons.blur_off,
                size: 18,
                color: blurred
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.translate('blur_covers'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              // A tap on the switch is the switch's own; only the rest of the
              // row toggles the rating.
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: blurred,
                  onChanged: (value) => _setBlurred(settings, value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Toggles whether the rating is shown, keeping at least one on.
  void _toggleShown(SettingsManager settings, bool selected) {
    final current = List<String>.from(settings.contentPreferences);
    if (selected) {
      if (current.length > 1) current.remove(rating);
    } else if (!current.contains(rating)) {
      current.add(rating);
    }
    settings.setContentPreferences(current);
  }

  void _setBlurred(SettingsManager settings, bool blurred) {
    final current = List<String>.from(settings.blurredContentRatings);
    if (blurred) {
      if (!current.contains(rating)) current.add(rating);
    } else {
      current.remove(rating);
    }
    settings.setBlurredContentRatings(current);
  }
}

class _DesktopLogsView extends StatefulWidget {
  final LocalizationService l10n;

  const _DesktopLogsView({required this.l10n});

  @override
  State<_DesktopLogsView> createState() => _DesktopLogsViewState();
}

class _DesktopLogsViewState extends State<_DesktopLogsView> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];

  String get _logsText => _logs.join('\n');

  @override
  void initState() {
    super.initState();
    _logs = List.from(LoggingService.logs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _clearLogs() {
    LoggingService.clearLogs();
    setState(() => _logs = []);
    AppSnackBar.show(context, widget.l10n.translate('logs_cleared'));
  }

  void _copyLogs() {
    if (_logs.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _logsText));
    AppSnackBar.show(context, widget.l10n.translate('logs_copied'));
  }

  Future<void> _saveLogs() async {
    if (_logs.isEmpty) return;
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/mangabaka_logs.txt');
      await file.writeAsString(_logsText);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'MangaBaka Logs'),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to save logs: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DesktopPillButton(
              label: widget.l10n.translate('copy_logs'),
              icon: Icons.copy_rounded,
              onPressed: _logs.isEmpty ? null : _copyLogs,
            ),
            const SizedBox(width: 8),
            DesktopPillButton(
              label: widget.l10n.translate('save_logs'),
              icon: Icons.download_rounded,
              onPressed: _logs.isEmpty ? null : _saveLogs,
            ),
            const SizedBox(width: 8),
            DesktopPillButton(
              label: widget.l10n.translate('clear_logs'),
              icon: Icons.delete_outline_rounded,
              onPressed: _logs.isEmpty ? null : _clearLogs,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DesktopCard(
            showBorder: false,
            padding: const EdgeInsets.all(16),
            child: SizedBox.expand(
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'No logs recorded yet',
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              _logs[index],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: context.colors.text,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
