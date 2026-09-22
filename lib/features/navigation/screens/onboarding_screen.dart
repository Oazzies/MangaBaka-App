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
import 'package:mangabaka_app/features/navigation/widgets/onboarding/login_page.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/onboarding/onboarding_window.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
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
  List<({String titleKey, Widget page})> get _steps => [
    (titleKey: 'onboarding_welcome_title', page: const WelcomePage()),
    (titleKey: 'onboarding_language_title', page: const LanguagePage()),
    (titleKey: 'onboarding_theme_title', page: const ThemePage()),
    (
      titleKey: 'onboarding_content_title',
      page: const ContentPreferencesPage(),
    ),
    if (!_isDesktop)
      (
        titleKey: 'onboarding_camera_title',
        page: CameraPermissionPage(
          onRequestPermission: _requestCameraPermission,
        ),
      ),
    (
      titleKey: 'onboarding_login_title',
      page: LoginPage(
        isLoggingIn: _isLoggingIn,
        isLoggedIn: _isLoggedIn,
        onLogin: _login,
      ),
    ),
  ];

  int get _totalPages => _steps.length;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) OnboardingWindow.enter();
    _logger.info('Onboarding started (isRedoing: ${widget.isRedoing})');
    _authService = getIt<ProfileAuthService>();
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void dispose() {
    if (_isDesktop) OnboardingWindow.exit();
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
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Row(
        children: [
          DesktopSidePanel(width: 340, child: _brandPanel()),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Expanded(child: _pageView()),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo, and the whole flow laid out as a numbered list so the user can see
  /// where they are and what is left — the thing a row of dots cannot say.
  Widget _brandPanel() {
    final l10n = LocalizationService();
    final steps = _steps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 48, 36, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/mangabaka512.png', width: 56, height: 56),
          const SizedBox(height: 20),
          Text(
            AppConstants.appName.toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 28,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.translate('onboarding_welcome_subtitle'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Spacer(),
          for (var i = 0; i < steps.length; i++)
            _stepRow(i, l10n.translate(steps[i].titleKey)),
        ],
      ),
    );
  }

  Widget _stepRow(int index, String title) {
    final isCurrent = index == _currentPage;
    final isDone = index < _currentPage;
    final color = isCurrent
        ? context.colors.text
        : (isDone ? context.colors.textMuted : context.colors.border);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            width: isCurrent ? 22 : 8,
            height: 2,
            color: isCurrent
                ? context.colors.accent
                : context.colors.surfaceRaised,
          ),
          const SizedBox(width: 14),
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: AppTypography.monoLabel(
              color: isCurrent ? context.colors.accent : color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(color: color, fontSize: 14),
            ),
          ),
          if (isDone)
            Icon(Icons.check_rounded, size: 16, color: context.colors.accent),
        ],
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
