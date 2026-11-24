import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

Future<bool> confirmListAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  IconData icon = Icons.delete_outline_rounded,
}) async {
  final l10n = LocalizationService();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      return AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          side: BorderSide(color: c.surfaceRaised, width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(color: c.text, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: AppTypography.sans(
            color: c.textMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.translate('cancel'),
              style: AppTypography.sans(
                color: c.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            key: const ValueKey('list_confirm_action'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: c.error,
              foregroundColor: c.on(c.error),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}
