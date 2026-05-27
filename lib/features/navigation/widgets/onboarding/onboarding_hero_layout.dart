import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

/// A shared centered hero layout used across onboarding pages.
///
/// Displays a rounded icon badge, a title, a subtitle, and an optional
/// action widget (e.g. a button) below the subtitle. Adapts sizing via
/// [isShort] for screens with limited vertical space.
class OnboardingHeroLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isShort;

  /// Normal-height title font size. Short screens always use 24pt.
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double? titleLetterSpacing;

  /// Optional widget rendered below the subtitle (e.g. a FilledButton).
  final Widget? action;

  const OnboardingHeroLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isShort,
    this.titleFontSize = 28,
    this.titleFontWeight = FontWeight.bold,
    this.titleLetterSpacing,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isShort ? 16 : 24),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: isShort ? 48 : 64,
                color: AppConstants.accentColor,
              ),
            ),
            SizedBox(height: isShort ? 24 : 40),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isShort ? 24 : titleFontSize,
                fontWeight: titleFontWeight,
                color: AppConstants.textColor,
                letterSpacing: titleLetterSpacing,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isShort ? 14 : 16,
                color: AppConstants.textMutedColor,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              SizedBox(height: isShort ? 24 : 40),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
