import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The signed-out state of an account-backed page, as a centred card.
class DesktopSignInPrompt extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onLogin;
  final IconData icon;

  const DesktopSignInPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.onLogin,
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DesktopCard(
          padding: const EdgeInsets.fromLTRB(36, 36, 36, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(
                  'assets/mangabaka512.png',
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              DesktopPillButton(
                label: l10n.translate('login_with'),
                icon: Icons.login_rounded,
                primary: true,
                onPressed: onLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
