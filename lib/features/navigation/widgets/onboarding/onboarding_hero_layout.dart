import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A shared centered hero layout used across onboarding pages.
///
/// Displays a rounded icon badge, a title, a subtitle, and an optional
/// action widget (e.g. a button) below the subtitle. Adapts sizing via
/// [isShort] for screens with limited vertical space.
class OnboardingHeroLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
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
    this.subtitle,
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
            MbEntrance(
              child: Icon(
                icon,
                size: isShort ? 56 : 72,
                color: context.colors.accent,
              ),
            ),
            SizedBox(height: isShort ? 24 : 40),
            MbEntrance(
              index: 1,
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.display(
                  fontSize: isShort ? 24 : titleFontSize,
                  color: context.colors.text,
                  height: 1.1,
                ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              MbEntrance(
                index: 2,
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    fontSize: isShort ? 14 : 16,
                    color: context.colors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: isShort ? 24 : 40),
              MbEntrance(index: 3, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
