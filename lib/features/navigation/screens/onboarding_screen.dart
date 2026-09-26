import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/welcome_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/language_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/theme_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/camera_permission_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/content_preferences_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/import_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/login_page.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/onboarding/onboarding_window.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_title_bar.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_window_frame.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:window_manager/window_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isRedoing;

  const OnboardingScreen({super.key, this.isRedoing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _logger = LoggingService.logger;
  final PageController _pageController = PageController();
  late final ProfileAuthService _authService;
  int _currentPage = 0;
  bool _isLoggingIn = false;
  bool _isLoggedIn = false;

  /// Desktop gets its own composition and a pinned window; the phone flow is
  /// left exactly as it was.
  final bool _isDesktop =
      // ignore: invalid_use_of_visible_for_testing_member
      DesktopLayout.debugOverride ?? DesktopLayout.isDesktopPlatform;

  /// Built on demand rather than cached: the login step reads live state
  /// ([_isLoggingIn], [_isLoggedIn]) and must see it change.
  ///
  /// Desktop has no barcode scanner to grant access to, so that step is
  /// dropped there.
  List<({String titleKey, IconData icon, Widget page})> get _steps => [
    (
      titleKey: 'onboarding_welcome_title',
      icon: Icons.auto_awesome_rounded,
      page: const WelcomePage(),
    ),
    (
      titleKey: 'onboarding_language_title',
      icon: Icons.translate_rounded,
      page: const LanguagePage(),
    ),
    (
      titleKey: 'onboarding_theme_title',
      icon: Icons.palette_outlined,
      page: const ThemePage(),
    ),
    (
      titleKey: 'onboarding_content_title',
      icon: Icons.tune_rounded,
      page: const ContentPreferencesPage(),
    ),
    if (!_isDesktop)
      (
        titleKey: 'onboarding_camera_title',
        icon: Icons.camera_alt_outlined,
        page: CameraPermissionPage(
          onRequestPermission: _requestCameraPermission,
        ),
      ),
    (
      titleKey: 'onboarding_login_title',
      icon: Icons.person_outline_rounded,
      page: LoginPage(
        isLoggingIn: _isLoggingIn,
        isLoggedIn: _isLoggedIn,
        onLogin: _login,
      ),
    ),
    (
      titleKey: 'onboarding_import_title',
      icon: Icons.import_export_rounded,
      page: const ImportPage(),
    ),
  ];

  int get _totalPages => _steps.length;

  void _goToPage(int page) {
    if (page == _currentPage || page < 0 || page >= _totalPages) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      OnboardingWindow.enter();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DesktopWindowFrame.hideTitleBar.value = true;
        DesktopShell.sidebarInset.value = 0;
      });
    }
    _logger.info('Onboarding started (isRedoing: ${widget.isRedoing})');
    _authService = getIt<ProfileAuthService>();
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void dispose() {
    if (_isDesktop) {
      OnboardingWindow.exit();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DesktopWindowFrame.hideTitleBar.value = false;
      });
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _logger.fine('Moving to onboarding page ${_currentPage + 2}');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _logger.fine('Moving back to onboarding page $_currentPage');
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() async {
    _logger.info('Finishing onboarding');
    await SettingsManager().setHasCompletedOnboarding(true);
    if (!mounted) return;

    if (widget.isRedoing) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _requestCameraPermission() async {
    _logger.info('Requesting camera permission during onboarding');
    // permission_handler does not support macOS — camera access is controlled
    // via the entitlements file and system dialog on first use.
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.info(
        'Platform does not use permission_handler; skipping request',
      );
      _nextPage();
      return;
    }
    final status = await Permission.camera.request();
    _logger.info('Camera permission status: $status');
    if (!mounted) return;
    _nextPage();
  }

  Future<void> _login() async {
    _logger.info('Starting login attempt during onboarding');
    setState(() => _isLoggingIn = true);
    try {
      await _authService.login();
      if (!mounted) return;
      _logger.info('Login successful during onboarding');
      setState(() => _isLoggedIn = true);
      _nextPage();
    } catch (e) {
      if (e is AuthCancelledException) {
        _logger.info('Login cancelled by user');
        return;
      }
      _logger.severe('Login failed during onboarding: $e');
      if (mounted) {
        final localization = LocalizationService();
        AppSnackBar.show(
          context,
          localization.translate('onboarding_login_failed'),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Widget _pageView() => PageView(
    controller: _pageController,
    scrollDirection: Axis.vertical,
    physics: const NeverScrollableScrollPhysics(),
    onPageChanged: (index) => setState(() => _currentPage = index),
    children: [for (final step in _steps) step.page],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        if (_isDesktop) return _desktopBody();
        return Scaffold(
          backgroundColor: context.colors.background,
          body: WidgetUtils.responsiveConstraint(
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: _pageView()),
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Desktop ───────────────────────────────────────────────────────────────

  Widget _desktopBody() {
    final l10n = LocalizationService();
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          // ── Sticky Top Bar with Window Controls ──
          Container(
            height: DesktopTitleBar.height,
            decoration: BoxDecoration(
              color: context.colors.background,
              border: Border(
                bottom: BorderSide(
                  color: context.colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: DesktopTitleBar.height,
                    child: DragToMoveArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ONBOARDING',
                            style: AppTypography.monoLabel(
                              color: context.colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: DesktopWindowButtons(
                    showMaximize: false,
                    onClose: widget.isRedoing
                        ? () => Navigator.of(context).pop()
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // ── Main Body (Sidebar + Content) ──
          Expanded(
            child: Row(
              children: [
                DesktopSidePanel(width: 280, child: _brandPanel()),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(36, 24, 36, 16),
                              child: _pageView(),
                            ),
                          ),
                        ),
                      ),
                      _buildDesktopBottomControls(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel() {
    final l10n = LocalizationService();
    final steps = _steps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Image.asset('assets/mangabaka512.png', width: 32, height: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConstants.appName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final step = steps[i];
                return _stepItem(
                  index: i,
                  title: l10n.translate(step.titleKey),
                  icon: step.icon,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preferences can be changed anytime in Settings.',
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isCurrent = index == _currentPage;
    final isDone = index < _currentPage;

    final fg = isCurrent ? context.colors.onAccent : context.colors.text;
    final iconColor = isCurrent
        ? context.colors.onAccent
        : (isDone ? context.colors.accent : context.colors.textMuted);

    return DesktopHoverSurface(
      onTap: () => _goToPage(index),
      selected: isCurrent,
      selectedColor: context.colors.accent,
      hoverColor: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: fg,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBottomControls(LocalizationService l10n) {
    final isLastPage = _currentPage == _totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(
          top: BorderSide(
            color: context.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                DesktopPillButton(
                  label: l10n.translate('onboarding_back'),
                  icon: Icons.arrow_back_rounded,
                  onPressed: _previousPage,
                )
              else
                DesktopPillButton(
                  label: l10n.translate('onboarding_skip'),
                  onPressed: _finishOnboarding,
                ),
              MbPrimaryButton(
                expand: false,
                label: isLastPage
                    ? l10n.translate('onboarding_finish')
                    : l10n.translate('onboarding_next'),
                trailingIcon: isLastPage
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: _nextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _totalPages - 1;
    final localization = LocalizationService();
    final screenHeight = MediaQuery.of(context).size.height;

    // Scale down spacing if height is small
    final isShort = screenHeight < 600;
    final bottomPadding = isShort ? 16.0 : 32.0;
    final spacingHeight = isShort ? 16.0 : 32.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected
                        ? context.colors.accent
                        : context.colors.surfaceRaised,
                  ),
                );
              }),
            ),
          if (!_isDesktop) SizedBox(height: spacingHeight),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: _previousPage,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textMuted,
                      padding: EdgeInsets.symmetric(
                        vertical: isShort ? 12 : 16,
                      ),
                    ),
                    child: Text(localization.translate('onboarding_back')),
                  ),
                )
              else
                Expanded(
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textMuted,
                      padding: EdgeInsets.symmetric(
                        vertical: isShort ? 12 : 16,
                      ),
                    ),
                    child: Text(localization.translate('onboarding_skip')),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: MbPrimaryButton(
                  label: isLastPage
                      ? localization.translate('onboarding_finish')
                      : localization.translate('onboarding_next'),
                  onPressed: _nextPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
