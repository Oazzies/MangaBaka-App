import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_dialogs.dart';

class StackEditorDetailsPane extends StatelessWidget {
  final StackEditorController controller;
  final LocalizationService l10n;
  final bool showErrors;
  final VoidCallback onDelete;

  const StackEditorDetailsPane({
    super.key,
    required this.controller,
    required this.l10n,
    required this.showErrors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final problems = showErrors
        ? controller.problems
        : const <StackEditorProblem>[];
    final titleError = problems.contains(StackEditorProblem.titleMissing)
        ? stackEditorProblemText(StackEditorProblem.titleMissing, l10n)
        : null;
    final publishBlocked = controller.liveCount < StackLimits.publishMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context, l10n.translate('stacks_field_title')),
        TextField(
          controller: controller.title,
          maxLength: StackLimits.titleMax,
          style: AppTypography.sans(
            color: c.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: _input(
            context,
            l10n.translate('stacks_title_hint'),
            error: titleError,
          ),
        ),
        _label(context, l10n.translate('stacks_field_description')),
        TextField(
          controller: controller.description,
          maxLength: StackLimits.descriptionMax,
          minLines: 4,
          maxLines: 12,
          style: AppTypography.sans(color: c.text, fontSize: 14, height: 1.4),
          decoration: _input(
            context,
            l10n.translate('stacks_description_hint'),
          ).copyWith(helperText: l10n.translate('stacks_markdown_hint')),
        ),
        _label(context, l10n.translate('stacks_field_visibility')),
        Row(
          children: [
            for (final v in StackVisibility.values) ...[
              if (v.index > 0) const SizedBox(width: 8),
              Expanded(
                child: MbPill(
                  label: l10n.translate(v.labelKey),
                  selected: controller.visibility == v,
                  expand: true,
                  onTap: () => controller.setVisibility(v),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.translate('stacks_visibility_${controller.visibility.name}_hint'),
          style: AppTypography.sans(
            color: c.textMuted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        if (controller.visibility.isListed && publishBlocked)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n
                  .translate('stacks_publish_needs')
                  .replaceAll('{n}', '${StackLimits.publishMin}'),
              style: AppTypography.sans(color: c.warning, fontSize: 12.5),
            ),
          ),
        _label(context, l10n.translate('stacks_field_rating')),
        Align(
          alignment: Alignment.centerLeft,
          child: MbDropdown<String>(
            label: l10n.translate('stacks_field_rating'),
            icon: Icons.shield_outlined,
            value: controller.contentRating,
            options: [
              for (final r in ContentRatingFilter.all) (r, l10n.translate(r)),
            ],
            onChanged: controller.setRating,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          controller.ratingTooLow
              ? l10n
                    .translate('stacks_rating_warning')
                    .replaceAll(
                      '{rating}',
                      l10n.translate(controller.suggestedRating),
                    )
              : l10n.translate('stacks_rating_hint'),
          style: AppTypography.sans(
            color: controller.ratingTooLow ? c.warning : c.textMuted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.isSpoiler,
          onChanged: controller.isSpoilerLocked ? null : controller.setSpoiler,
          activeTrackColor: c.accent,
          title: Text(
            l10n.translate('stacks_field_spoiler'),
            style: AppTypography.sans(
              color: c.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.translate(
              controller.isSpoilerLocked
                  ? 'stacks_spoiler_locked'
                  : 'stacks_spoiler_hint',
            ),
            style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.commentsEnabled,
          onChanged: controller.setComments,
          activeTrackColor: c.accent,
          title: Text(
            l10n.translate('stacks_field_comments'),
            style: AppTypography.sans(
              color: c.text,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.translate('stacks_comments_hint'),
            style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
          ),
        ),
        if (!controller.isNew && !DesktopLayout.isActive(context)) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: c.error),
            label: Text(
              l10n.translate('stacks_delete'),
              style: TextStyle(color: c.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 18),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.display(
        color: context.colors.textMuted,
        fontSize: 12,
      ),
    ),
  );

  // Every state border is set here so the app's pill input theme does not win.
  InputDecoration _input(BuildContext context, String hint, {String? error}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: context.colors.surfaceRaised,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: border,
      focusedErrorBorder: border,
    );
  }
}
