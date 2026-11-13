import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
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
import 'package:mangabaka_app/features/navigation/widgets/onboarding/open_links_page.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_bottom_controls.dart';
import 'package:mangabaka_app/features/navigation/widgets/onboarding/onboarding_desktop_shell.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/onboarding/onboarding_window.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_window_frame.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
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
  List<OnboardingStep> get _steps => [
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
    if (Platform.isAndroid || Platform.isIOS)
      (
        titleKey: 'onboarding_links_title',
        icon: Icons.link_rounded,
        page: const OpenLinksPage(),
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
    } on AuthCancelledException {
      _logger.info('Login cancelled by user');
    } catch (e, st) {
      _logger.severe('Login failed during onboarding', e, st);
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
    scrollDirection: _isDesktop ? Axis.vertical : Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    onPageChanged: (index) => setState(() => _currentPage = index),
    children: [for (final step in _steps) step.page],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        if (_isDesktop) {
          return OnboardingDesktopShell(
            steps: _steps,
            currentPage: _currentPage,
            pageView: _pageView(),
            isRedoing: widget.isRedoing,
            onSelectPage: _goToPage,
            onPrevious: _previousPage,
            onNext: _nextPage,
            onSkip: _finishOnboarding,
          );
        }
        return Scaffold(
          backgroundColor: context.colors.background,
          body: WidgetUtils.responsiveConstraint(
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: _pageView()),
                  OnboardingBottomControls(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    isDesktop: _isDesktop,
                    onPrevious: _previousPage,
                    onSkip: _finishOnboarding,
                    onNext: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
