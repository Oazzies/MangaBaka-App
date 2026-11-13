import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/complete_progress_dialog.dart';

/// User's choice from [showCompleteSeriesDialog] about marking the series as
/// completed and optionally maxing out the remaining progress field.
class CompleteSeriesChoice {
  final bool markCompleted;
  final bool updateOtherProgress;

  const CompleteSeriesChoice({
    required this.markCompleted,
    required this.updateOtherProgress,
  });
}

/// Checks whether reaching the final chapter or volume of a completed series
/// should prompt the user to mark it as Completed (and max out the other
/// progress field), and performs the update if confirmed.
Future<void> maybePromptCompleteSeries(
  BuildContext context, {
  required Series series,
  required LibraryEntry entry,
  required LibraryService libraryService,
  int? previousChapter,
  int? updatedChapter,
  int? previousVolume,
  int? updatedVolume,
}) async {
  if (SettingsManager().autoCompleteSeriesStatus !=
      AutoCompleteProgressMode.prompt) {
    return;
  }
  if (series.status.toLowerCase() != 'completed') return;
  if (entry.state == 'completed') return;

  final totalChapters = int.tryParse(series.totalChapters);
  final totalVolumes = int.tryParse(series.finalVolume);
  final prevChapter = previousChapter ?? entry.progressChapter ?? 0;
  final prevVolume = previousVolume ?? entry.progressVolume ?? 0;

  final reachedChapters =
      updatedChapter != null &&
      totalChapters != null &&
      totalChapters > 0 &&
      prevChapter < totalChapters &&
      updatedChapter >= totalChapters;
  final reachedVolumes =
      updatedVolume != null &&
      totalVolumes != null &&
      totalVolumes > 0 &&
      prevVolume < totalVolumes &&
      updatedVolume >= totalVolumes;

  if (!reachedChapters && !reachedVolumes) return;

  final l10n = LocalizationService();
  final bool canUpdateOther;
  final String? otherLabel;
  final int? otherCurrent;
  final int? otherTotal;

  if (reachedChapters && !reachedVolumes) {
    canUpdateOther =
        totalVolumes != null && totalVolumes > 0 && prevVolume < totalVolumes;
    otherLabel = canUpdateOther ? l10n.translate('volumes') : null;
    otherCurrent = canUpdateOther ? prevVolume : null;
    otherTotal = canUpdateOther ? totalVolumes : null;
  } else {
    canUpdateOther =
        totalChapters != null &&
        totalChapters > 0 &&
        prevChapter < totalChapters;
    otherLabel = canUpdateOther ? l10n.translate('chapters') : null;
    otherCurrent = canUpdateOther ? prevChapter : null;
    otherTotal = canUpdateOther ? totalChapters : null;
  }

  if (!context.mounted) return;
  final choice = await showCompleteSeriesDialog(
    context,
    currentState: entry.state,
    otherProgressLabel: otherLabel,
    otherCurrent: otherCurrent,
    otherTotal: otherTotal,
  );
  if (choice == null || !choice.markCompleted) return;

  try {
    await libraryService.updateLibraryEntryState(
      series.id,
      'completed',
      totalChapters: totalChapters,
      totalVolumes: totalVolumes,
      completeChapters:
          reachedVolumes && canUpdateOther && choice.updateOtherProgress,
      completeVolumes:
          reachedChapters && canUpdateOther && choice.updateOtherProgress,
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackBar.show(
        context,
        l10n.translate('failed_to_update'),
        isError: true,
      );
    }
  }
}

/// Prompts whether to mark a series as Completed and optionally max out the
/// remaining progress field (chapters or volumes).
Future<CompleteSeriesChoice?> showCompleteSeriesDialog(
  BuildContext context, {
  required String currentState,
  String? otherProgressLabel,
  int? otherCurrent,
  int? otherTotal,
}) {
  return showDialog<CompleteSeriesChoice>(
    context: context,
    builder: (context) => _CompleteSeriesDialog(
      currentState: currentState,
      otherProgressLabel: otherProgressLabel,
      otherCurrent: otherCurrent,
      otherTotal: otherTotal,
    ),
  );
}

class _CompleteSeriesDialog extends StatefulWidget {
  final String currentState;
  final String? otherProgressLabel;
  final int? otherCurrent;
  final int? otherTotal;

  const _CompleteSeriesDialog({
    required this.currentState,
    this.otherProgressLabel,
    this.otherCurrent,
    this.otherTotal,
  });

  @override
  State<_CompleteSeriesDialog> createState() => _CompleteSeriesDialogState();
}

class _CompleteSeriesDialogState extends State<_CompleteSeriesDialog> {
  late bool _updateOther = _hasOther;

  bool get _hasOther =>
      widget.otherProgressLabel != null &&
      widget.otherCurrent != null &&
      widget.otherTotal != null;

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
              Icons.task_alt_rounded,
              color: context.colors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('complete_series_title').toUpperCase(),
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
            l10n.translate('complete_series_message'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          CompleteDialogChangeRow(
            label: l10n.translate('complete_series_status_label'),
            fromText: l10n.translate(widget.currentState),
            toText: l10n.translate('completed'),
            showCheckbox: false,
            checked: true,
            onChanged: null,
          ),
          if (_hasOther) ...[
            const SizedBox(height: 8),
            CompleteDialogChangeRow(
              label: widget.otherProgressLabel!,
              fromText: '${widget.otherCurrent!}',
              toText: '${widget.otherTotal!}',
              showCheckbox: true,
              checked: _updateOther,
              onChanged: (v) => setState(() => _updateOther = v ?? false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const CompleteSeriesChoice(
              markCompleted: false,
              updateOtherProgress: false,
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
          onPressed: () => Navigator.pop(
            context,
            CompleteSeriesChoice(
              markCompleted: true,
              updateOtherProgress: _updateOther,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.accent,
            foregroundColor: context.colors.on(context.colors.accent),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
          ),
          child: Text(
            l10n.translate('complete_series_confirm'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
