import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Asks before a series is removed from the library. Resolves true on confirm.
Future<bool?> showDeleteFromLibraryDialog(BuildContext context) {
  final l10n = LocalizationService();
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: BorderSide(color: context.colors.surfaceRaised, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_sweep_rounded,
              color: context.colors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('delete_from_library').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.translate('delete_confirmation'),
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            l10n.translate('cancel'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.on(context.colors.error),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
          ),
          child: Text(
            l10n.translate('confirm'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
