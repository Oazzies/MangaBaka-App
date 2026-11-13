import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/features/series/widgets/note_editor_toolbar.dart';
import 'package:mangabaka_app/features/series/widgets/note_markdown_helpers.dart';
import 'package:mangabaka_app/features/series/widgets/series_note_markdown.dart';

/// Adaptive bottom-sheet / dialog editor for a series' personal library note,
/// with a Markdown formatting toolbar and live Markdown preview.
class NoteEditorDialog extends StatefulWidget {
  final String? initialNote;
  final ValueChanged<String> onSave;

  const NoteEditorDialog({
    super.key,
    this.initialNote,
    required this.onSave,
  });

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _previewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave(_controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final hasInitial =
        widget.initialNote != null && widget.initialNote!.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdaptiveSheetHandle(bottomSpacing: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: c.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n
                        .translate(
                          hasInitial
                              ? 'series_note_edit_title'
                              : 'series_note_add_title',
                        )
                        .toUpperCase(),
                    style: AppTypography.display(
                      color: c.text,
                      fontSize: 18,
                    ),
                  ),
                ),
                NoteEditorModeSwitch(
                  previewMode: _previewMode,
                  writeLabel: l10n.translate('series_note_write'),
                  previewLabel: l10n.translate('series_note_preview'),
                  onChanged: (preview) {
                    setState(() => _previewMode = preview);
                    if (!preview) {
                      _focusNode.requestFocus();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_previewMode) ...[
              NoteMarkdownToolbar(
                onBold: () => NoteMarkdownHelper.wrapSelection(
                  _controller,
                  _focusNode,
                  '**',
                  '**',
                  'bold',
                ),
                onItalic: () => NoteMarkdownHelper.wrapSelection(
                  _controller,
                  _focusNode,
                  '*',
                  '*',
                  'italic',
                ),
                onStrike: () => NoteMarkdownHelper.wrapSelection(
                  _controller,
                  _focusNode,
                  '~~',
                  '~~',
                  'text',
                ),
                onHeading: () => NoteMarkdownHelper.prefixLine(
                  _controller,
                  _focusNode,
                  '# ',
                ),
                onBullet: () => NoteMarkdownHelper.prefixLine(
                  _controller,
                  _focusNode,
                  '- ',
                ),
                onQuote: () => NoteMarkdownHelper.prefixLine(
                  _controller,
                  _focusNode,
                  '> ',
                ),
                onCode: () => NoteMarkdownHelper.wrapSelection(
                  _controller,
                  _focusNode,
                  '`',
                  '`',
                  'code',
                ),
                onLink: () =>
                    NoteMarkdownHelper.insertLink(_controller, _focusNode),
              ),
              const SizedBox(height: 10),
              CallbackShortcuts(
                bindings: NoteMarkdownHelper.buildShortcuts(
                  _controller,
                  _focusNode,
                  _handleSave,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  minLines: 5,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.translate('series_note_hint'),
                    hintStyle: AppTypography.sans(
                      color: c.textMuted,
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: c.surfaceRaised,
                    contentPadding: const EdgeInsets.all(14),
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
              ),
            ] else ...[
              Container(
                constraints: const BoxConstraints(
                  minHeight: 150,
                  maxHeight: 280,
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: _controller.text.trim().isEmpty
                    ? Text(
                        l10n.translate('series_note_preview_empty'),
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 13.5,
                        ),
                      )
                    : SingleChildScrollView(
                        child: SeriesNoteMarkdown(
                          data: _controller.text.trim(),
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 20),
            NoteEditorActionsRow(
              controller: _controller,
              hasInitial: hasInitial,
              l10n: l10n,
              onCleared: () {
                _controller.clear();
                if (_previewMode) {
                  setState(() {});
                }
              },
              onCancel: () => Navigator.of(context).pop(),
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
