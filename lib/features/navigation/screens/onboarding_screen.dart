import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakahyou/features/navigation/screens/main_screen.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/welcome_page.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/language_page.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/theme_page.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/camera_permission_page.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/content_preferences_page.dart';
import 'package:bakahyou/features/navigation/widgets/onboarding/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isRedoing;

  const OnboardingScreen({super.key, this.isRedoing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final ProfileAuthService _authService;
  int _currentPage = 0;
  bool _isLoggingIn = false;
  bool _isLoggedIn = false;

  static const int _totalPages = 6;

  final List<String> _contentOptions = ['safe', 'suggestive', 'erotica', 'pornographic'];

  @override
  void initState() {
    super.initState();
    _authService = getIt<ProfileAuthService>();
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
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
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() async {
    await SettingsManager().setHasCompletedOnboarding(true);
    if (!mounted) return;

    if (widget.isRedoing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
    _nextPage();
  }

  Future<void> _login() async {
    setState(() => _isLoggingIn = true);
    try {
      await _authService.login();
      setState(() => _isLoggedIn = true);
      _nextPage();
    } catch (e) {
      if (e is AuthCancelledException) return;
      if (mounted) {
        final localization = LocalizationService();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('onboarding_login_failed'), style: TextStyle(color: AppConstants.errorColor)),
            backgroundColor: AppConstants.secondaryBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      const WelcomePage(),
                      const LanguagePage(),
                      const ThemePage(),
                      ContentPreferencesPage(
                        contentOptions: _contentOptions,
                      ),
                      CameraPermissionPage(
                        onRequestPermission: _requestCameraPermission,
                      ),
                      LoginPage(
                        isLoggingIn: _isLoggingIn,
                        isLoggedIn: _isLoggedIn,
                        onLogin: _login,
                      ),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == _totalPages - 1;
    final localization = LocalizationService();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalPages,
              (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isSelected
                        ? AppConstants.accentColor
                        : AppConstants.textMutedColor.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: TextButton(
                    onPressed: _previousPage,
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textMutedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(localization.translate('onboarding_back')),
                  ),
                )
              else
                Expanded(
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.textMutedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(localization.translate('onboarding_skip')),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: AppConstants.primaryBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isLastPage 
                        ? localization.translate('onboarding_finish') 
                        : localization.translate('onboarding_next'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
