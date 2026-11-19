import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/adaptive_form.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

Future<String?> showStackNoteForm(
  BuildContext context,
  EditableStackEntry entry,
) => showAdaptiveForm<String>(
  context: context,
  title: LocalizationService().translate('stacks_note_edit'),
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => StackEditorNoteForm(entry: entry),
);

class StackEditorNoteForm extends StatefulWidget {
  final EditableStackEntry entry;

  const StackEditorNoteForm({super.key, required this.entry});

  @override
  State<StackEditorNoteForm> createState() => _StackEditorNoteFormState();
}

class _StackEditorNoteFormState extends State<StackEditorNoteForm> {
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
    final page = AdaptiveFormPage.isPage(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    if (!page) ...[
                      Text(
                        _l10n.translate('stacks_note_edit').toUpperCase(),
                        style: AppTypography.display(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
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
            style: AppTypography.sans(color: c.text, fontSize: 14, height: 1.4),
            decoration: InputDecoration(
              hintText:
                  '${_l10n.translate('stacks_note_hint')}\n'
                  '${_l10n.translate('stacks_markdown_hint')}',
              hintMaxLines: 4,
              filled: true,
              fillColor: c.surfaceRaised,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
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
    );
  }
}
