import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bakahyou/features/navigation/screens/main_screen.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';

import 'package:bakahyou/features/navigation/widgets/onboarding/welcome_page.dart';
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

  static const int _totalPages = 5;

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await SettingsManager().setHasCompletedOnboarding(true);
    if (!mounted) return;

    if (widget.isRedoing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppConstants.primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: AppConstants.textMutedColor),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      WelcomePage(),
                      ThemePage(),
                      CameraPermissionPage(
                        onRequestPermission: _requestCameraPermission,
                      ),
                      ContentPreferencesPage(
                        contentOptions: _contentOptions,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot indicators
          Row(
            children: List.generate(
              _totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppConstants.accentColor
                      : AppConstants.textMutedColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.primaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              _currentPage == _totalPages - 1 ? 'Finish' : 'Next',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
