import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class LoginPage extends StatelessWidget {
  final bool isLoggingIn;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  const LoginPage({
    super.key,
    required this.isLoggingIn,
    required this.isLoggedIn,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Sign In',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Log in with your MangaBaka account to sync your library, reading progress, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textMutedColor,
            ),
          ),
          const SizedBox(height: 48),
          if (isLoggedIn)
            Column(
              children: [
                Icon(Icons.check_circle, color: AppConstants.successColor, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Successfully logged in!',
                  style: TextStyle(color: AppConstants.successColor, fontSize: 18),
                ),
              ],
            )
          else if (isLoggingIn)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
              ),
              child: const Text(
                'Login with MangaBaka',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
