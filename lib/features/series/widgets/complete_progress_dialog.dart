import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// User's choice from [showCompleteProgressDialog] about which progress fields
/// to set to the series's latest totals.
class CompleteProgressChoice {
  final bool updateChapters;
  final bool updateVolumes;

  const CompleteProgressChoice({
    required this.updateChapters,
    required this.updateVolumes,
  });
}

/// Prompts whether to set chapter and/or volume progress to the latest totals
/// when marking a series as completed.
Future<CompleteProgressChoice?> showCompleteProgressDialog(
  BuildContext context, {
  required int currentChapter,
  int? totalChapters,
  required int currentVolume,
  int? totalVolumes,
}) {
  final chaptersCanUpdate =
      totalChapters != null &&
      totalChapters > 0 &&
      currentChapter < totalChapters;
  final volumesCanUpdate =
      totalVolumes != null &&
      totalVolumes > 0 &&
      currentVolume < totalVolumes;

  return showDialog<CompleteProgressChoice>(
    context: context,
    builder: (context) => _CompleteProgressDialog(
      currentChapter: currentChapter,
      totalChapters: chaptersCanUpdate ? totalChapters : null,
      currentVolume: currentVolume,
      totalVolumes: volumesCanUpdate ? totalVolumes : null,
    ),
  );
}

class _CompleteProgressDialog extends StatefulWidget {
  final int currentChapter;
  final int? totalChapters;
  final int currentVolume;
  final int? totalVolumes;

  const _CompleteProgressDialog({
    required this.currentChapter,
    required this.totalChapters,
    required this.currentVolume,
    required this.totalVolumes,
  });

  @override
  State<_CompleteProgressDialog> createState() =>
      _CompleteProgressDialogState();
}

class _CompleteProgressDialogState extends State<_CompleteProgressDialog> {
  late bool _updateChapters = widget.totalChapters != null;
  late bool _updateVolumes = widget.totalVolumes != null;

  bool get _hasBoth =>
      widget.totalChapters != null && widget.totalVolumes != null;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return AlertDialog(
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
              Icons.check_circle_outline_rounded,
              color: context.colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('complete_progress_title').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('complete_progress_message'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.totalChapters != null)
            CompleteDialogChangeRow(
              label: l10n.translate('chapters'),
              fromText: '${widget.currentChapter}',
              toText: '${widget.totalChapters!}',
              showCheckbox: _hasBoth,
              checked: _updateChapters,
              onChanged: (v) => setState(() => _updateChapters = v ?? false),
            ),
          if (widget.totalVolumes != null) ...[
            if (widget.totalChapters != null) const SizedBox(height: 8),
            CompleteDialogChangeRow(
              label: l10n.translate('volumes'),
              fromText: '${widget.currentVolume}',
              toText: '${widget.totalVolumes!}',
              showCheckbox: _hasBoth,
              checked: _updateVolumes,
              onChanged: (v) => setState(() => _updateVolumes = v ?? false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const CompleteProgressChoice(
              updateChapters: false,
              updateVolumes: false,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            l10n.translate('complete_progress_keep'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: (_updateChapters || _updateVolumes)
              ? () => Navigator.pop(
                  context,
                  CompleteProgressChoice(
                    updateChapters: _updateChapters,
                    updateVolumes: _updateVolumes,
                  ),
                )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.accent,
            foregroundColor: context.colors.on(context.colors.accent),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
          ),
          child: Text(
            l10n.translate('complete_progress_update'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// A row displaying a `from → to` change, with an optional checkbox.
class CompleteDialogChangeRow extends StatelessWidget {
  final String label;
  final String fromText;
  final String toText;
  final bool showCheckbox;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  const CompleteDialogChangeRow({
    super.key,
    required this.label,
    required this.fromText,
    required this.toText,
    required this.showCheckbox,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: EdgeInsets.symmetric(
        horizontal: showCheckbox ? 8 : 14,
        vertical: showCheckbox ? 4 : 10,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.denseRadius),
      ),
      child: Row(
        children: [
          if (showCheckbox)
            Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: context.colors.accent,
            ),
          Expanded(
            child: Text(
              label,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$fromText → $toText',
            style: AppTypography.sans(
              color: context.colors.accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (!showCheckbox || onChanged == null) return row;
    return InkWell(
      onTap: () => onChanged!(!checked),
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
      child: row,
    );
  }
}
