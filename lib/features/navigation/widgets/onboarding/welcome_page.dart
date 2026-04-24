import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 100,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to BakaHyou',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your ultimate companion for MangaBaka. Let\'s get your experience set up.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
