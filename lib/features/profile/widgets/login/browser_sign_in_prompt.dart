import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Laid over the whole app while a desktop sign-in waits on the browser.
///
/// The browser is another program, so nothing tells the app when its tab was
/// closed. Without this the only feedback was a button that spun until the
/// five-minute timeout; here the user is told where to look and can back out.
class BrowserSignInPrompt extends StatelessWidget {
  final Widget child;

  const BrowserSignInPrompt({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = getIt<ProfileAuthService>();
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: auth.awaitingBrowser,
          builder: (context, waiting, _) {
            if (!waiting) return const SizedBox.shrink();
            return _Card(auth: auth);
          },
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final ProfileAuthService auth;

  const _Card({required this.auth});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Positioned.fill(
      child: Material(
        color: FixedColors.dim.withValues(
          alpha: context.colors.isDark ? 0.72 : 0.45,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.colors.accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.translate('auth_waiting_title').toUpperCase(),
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.translate('auth_waiting_body'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: auth.cancelLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.textMuted,
                        ),
                        child: Text(l10n.translate('cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: auth.reopenBrowser,
                        child: Text(l10n.translate('auth_reopen_browser')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
