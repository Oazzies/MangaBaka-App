import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

class ListsSignInPrompt extends StatelessWidget {
  final ProfileAuthService auth;

  const ListsSignInPrompt({super.key, required this.auth});

  Future<void> _login(BuildContext context) async {
    try {
      await auth.login();
    } on AuthCancelledException {
      return;
    } catch (e, st) {
      LoggingService.logger.severe('Lists: sign in failed', e, st);
      if (context.mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('login_failed_retry'),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_list_bulleted_rounded,
              size: 48,
              color: c.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('login_prompt_lists'),
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: c.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 20),
            MbPrimaryButton(
              expand: false,
              label: l10n.translate('sign_in'),
              onPressed: () => _login(context),
            ),
          ],
        ),
      ),
    );
  }
}
