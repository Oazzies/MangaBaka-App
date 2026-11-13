import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

String stackEditorProblemText(
  StackEditorProblem p,
  LocalizationService l10n,
) => switch (p) {
  StackEditorProblem.titleMissing => l10n.translate('stacks_problem_title'),
  StackEditorProblem.titleTooLong =>
    l10n
        .translate('stacks_problem_title_long')
        .replaceAll('{n}', '${StackLimits.titleMax}'),
  StackEditorProblem.descriptionTooLong =>
    l10n
        .translate('stacks_problem_description_long')
        .replaceAll('{n}', '${StackLimits.descriptionMax}'),
  StackEditorProblem.noteTooLong =>
    l10n
        .translate('stacks_problem_note_long')
        .replaceAll('{n}', '${StackLimits.noteMax}'),
  StackEditorProblem.tooManyEntries =>
    l10n
        .translate('stacks_problem_too_many')
        .replaceAll('{n}', '${StackLimits.entriesMax}'),
  StackEditorProblem.tooFewToPublish =>
    l10n
        .translate('stacks_publish_needs')
        .replaceAll('{n}', '${StackLimits.publishMin}'),
  StackEditorProblem.ratingBelowMinimum => l10n.translate(
    'stacks_error_rating_below_minimum',
  ),
};

/// Null: cancel. True: raise it. False: keep it and try anyway.
Future<bool?> askRaiseStackRatingDialog(
  BuildContext context, {
  required String suggestedRatingKey,
  required LocalizationService l10n,
}) {
  final suggested = l10n.translate(suggestedRatingKey);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(l10n.translate('stacks_rating_raise_title')),
      content: Text(
        l10n
            .translate('stacks_rating_raise_body')
            .replaceAll('{rating}', suggested),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('stacks_rating_keep')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n
                .translate('stacks_rating_raise')
                .replaceAll('{rating}', suggested),
          ),
        ),
      ],
    ),
  );
}

Future<String?> askStaleStackDialog(
  BuildContext context,
  LocalizationService l10n,
) => showDialog<String>(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: context.colors.surface,
    title: Text(l10n.translate('stacks_stale_title')),
    content: Text(l10n.translate('stacks_stale_body')),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop('reload'),
        child: Text(l10n.translate('stacks_stale_reload')),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop('overwrite'),
        child: Text(l10n.translate('stacks_stale_overwrite')),
      ),
    ],
  ),
);

Future<bool> confirmDiscardStackEditsDialog(
  BuildContext context,
  LocalizationService l10n,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(l10n.translate('stacks_discard_title')),
      content: Text(l10n.translate('stacks_discard_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('stacks_keep_editing')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.translate('stacks_discard'),
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
