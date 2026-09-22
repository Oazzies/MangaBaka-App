import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/profile/widgets/login/mb_login_button.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MBLoginPrompt extends StatelessWidget {
  final VoidCallback onLogin;
  final String message;

  const MBLoginPrompt({
    super.key,
    required this.onLogin,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.sans(fontSize: 18, color: context.colors.text),
          ),
          const SizedBox(height: 20),
          MBLoginButton(onPressed: onLogin),
        ],
      ),
    );
  }
}
