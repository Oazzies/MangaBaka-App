import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Asks before a blurred cover is opened fullscreen, where it is shown clear.
///
/// A cover is blurred because the user asked for that rating to be; opening it
/// fullscreen undoes the blur, and one stray click should not do that
/// unannounced. Resolves true if they choose to go ahead.
Future<bool> confirmUnblur(BuildContext context) async {
  final l10n = LocalizationService();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Icon(Icons.blur_off, color: context.colors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('unblur_cover_title').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(
          l10n.translate('unblur_cover_message'),
          style: AppTypography.sans(
            color: context.colors.text,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n.translate('cancel'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.accent,
            foregroundColor: context.colors.onAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
          ),
          child: Text(
            l10n.translate('unblur_cover_confirm'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
