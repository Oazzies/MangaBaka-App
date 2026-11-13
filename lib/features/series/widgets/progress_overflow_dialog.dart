import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Outcome of checking whether a progress update that exceeds the known total
/// is allowed.
enum ProgressOverflowDecision {
  /// No overflow or the current setting allows it without prompting.
  allowed,

  /// The current setting forbids exceeding the known total.
  blocked,

  /// The user should be prompted before proceeding.
  prompt,
}

/// Evaluates [mode] for a proposed [newValue] against [total] and
/// [seriesStatus] (the series' publication status, not the library entry state).
ProgressOverflowDecision evaluateProgressOverflow({
  required ProgressOverflowMode mode,
  required int newValue,
  required int? total,
  String? seriesStatus,
}) {
  if (total == null || total <= 0 || newValue <= total) {
    return ProgressOverflowDecision.allowed;
  }
  switch (mode) {
    case ProgressOverflowMode.always:
      return ProgressOverflowDecision.allowed;
    case ProgressOverflowMode.never:
      return ProgressOverflowDecision.blocked;
    case ProgressOverflowMode.prompt:
      return ProgressOverflowDecision.prompt;
    case ProgressOverflowMode.promptCompletedOnly:
      final isCompleted = seriesStatus?.toLowerCase() == 'completed';
      return isCompleted
          ? ProgressOverflowDecision.prompt
          : ProgressOverflowDecision.allowed;
  }
}

/// Checks whether [newValue] exceeds [total] under the active
/// [SettingsManager.progressOverflow] setting, prompting the user when needed.
///
/// Returns `true` if the update should proceed, `false` if blocked or declined.
Future<bool> confirmProgressOverflow(
  BuildContext context, {
  required int newValue,
  required int? total,
  required bool isChapter,
  String? seriesStatus,
}) async {
  final decision = evaluateProgressOverflow(
    mode: SettingsManager().progressOverflow,
    newValue: newValue,
    total: total,
    seriesStatus: seriesStatus,
  );
  switch (decision) {
    case ProgressOverflowDecision.allowed:
      return true;
    case ProgressOverflowDecision.blocked:
      return false;
    case ProgressOverflowDecision.prompt:
      if (!context.mounted) return false;
      return await showProgressOverflowDialog(
            context,
            newValue: newValue,
            total: total!,
            isChapter: isChapter,
          ) ??
          false;
  }
}

/// Prompts the user to confirm setting progress past the series' known total.
Future<bool?> showProgressOverflowDialog(
  BuildContext context, {
  required int newValue,
  required int total,
  required bool isChapter,
}) {
  final l10n = LocalizationService();
  final messageKey = isChapter
      ? 'progress_overflow_message_chapters'
      : 'progress_overflow_message_volumes';
  final message = l10n
      .translate(messageKey)
      .replaceAll('{value}', '$newValue')
      .replaceAll('{total}', '$total');

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: BorderSide(color: context.colors.surfaceRaised, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: context.colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('progress_overflow_title').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.translate('progress_overflow_confirm'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
