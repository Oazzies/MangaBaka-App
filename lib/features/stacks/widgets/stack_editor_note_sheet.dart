import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

/// The note editor: a sheet headed by the entry it is for, with a roomy field
/// and a running count against [StackLimits.noteMax]. Pops the new text.
class StackEditorNoteSheet extends StatefulWidget {
  final EditableStackEntry entry;

  const StackEditorNoteSheet({super.key, required this.entry});

  @override
  State<StackEditorNoteSheet> createState() => _StackEditorNoteSheetState();
}

class _StackEditorNoteSheetState extends State<StackEditorNoteSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.entry.note,
  );
  final LocalizationService _l10n = LocalizationService();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final series = widget.entry.series;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MbCover(
                    url: series?.coverUrl ?? '',
                    width: 40,
                    radius: 6,
                    memCacheWidth: 96,
                    blurred: WidgetUtils.isRatingBlurred(
                      series?.contentRating ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _l10n.translate('stacks_note_edit'),
                          style: AppTypography.display(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            color: c.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: StackLimits.noteMax,
                style: AppTypography.sans(
                  color: c.text,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _l10n.translate('stacks_note_hint'),
                  helperText: _l10n.translate('stacks_markdown_hint'),
                  filled: true,
                  fillColor: c.surfaceRaised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_l10n.translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MbPrimaryButton(
                      label: _l10n.translate('save'),
                      onPressed: () => Navigator.of(context).pop(_text.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
