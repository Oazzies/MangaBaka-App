import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

enum StackAccess {
  ready,

  signedOut,

  /// Signed in from before Stacks existed: the token lacks the scopes.
  needsReconnect,
}

StackAccess stackAccess(ProfileAuthService auth) {
  if (!auth.isLoggedIn) return StackAccess.signedOut;
  return auth.hasStackScopes ? StackAccess.ready : StackAccess.needsReconnect;
}

Future<bool> signInForStacks(
  BuildContext context,
  ProfileAuthService auth,
) async {
  final l10n = LocalizationService();
  try {
    await auth.login();
  } on AuthCancelledException {
    return false;
  } catch (e) {
    LoggingService.logger.warning('Stacks sign-in failed: $e');
    if (context.mounted) {
      AppSnackBar.show(
        context,
        l10n.translate('login_failed_retry'),
        isError: true,
      );
    }
    return false;
  }
  return auth.hasStackScopes;
}

Future<bool> ensureStackAccess(
  BuildContext context,
  ProfileAuthService auth,
) async {
  final access = stackAccess(auth);
  if (access == StackAccess.ready) return true;
  final l10n = LocalizationService();
  final reconnect = access == StackAccess.needsReconnect;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(
        l10n.translate(
          reconnect ? 'stacks_reconnect_title' : 'stacks_sign_in_title',
        ),
        style: AppTypography.sans(
          color: context.colors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.translate(
          reconnect ? 'stacks_reconnect_body' : 'stacks_sign_in_body',
        ),
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.translate(reconnect ? 'stacks_reconnect_action' : 'sign_in'),
          ),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  return signInForStacks(context, auth);
}

class StackAccessPrompt extends StatelessWidget {
  final StackAccess access;
  final ProfileAuthService auth;

  final VoidCallback? onReady;

  final String? signedOutMessage;

  const StackAccessPrompt({
    super.key,
    required this.access,
    required this.auth,
    this.onReady,
    this.signedOutMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final reconnect = access == StackAccess.needsReconnect;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                reconnect ? Icons.key_rounded : Icons.layers_rounded,
                color: c.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.translate(
                    reconnect
                        ? 'stacks_reconnect_title'
                        : 'stacks_sign_in_title',
                  ),
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reconnect
                ? l10n.translate('stacks_reconnect_body')
                : (signedOutMessage ?? l10n.translate('stacks_sign_in_body')),
            style: AppTypography.sans(
              color: c.textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          MbPrimaryButton(
            label: l10n.translate(
              reconnect ? 'stacks_reconnect_action' : 'sign_in',
            ),
            icon: Icons.login_rounded,
            onPressed: () async {
              if (await signInForStacks(context, auth)) onReady?.call();
            },
          ),
        ],
      ),
    );
  }
}
