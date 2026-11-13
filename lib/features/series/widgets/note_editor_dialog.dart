import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
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

  void _wrapSelection(String prefix, String suffix, String placeholder) {
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final inner = selected.isEmpty ? placeholder : selected;
    final replacement = '$prefix$inner$suffix';
    final nextText = text.replaceRange(start, end, replacement);

    final selectionStart = start + prefix.length;
    final selectionEnd = selectionStart + inner.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
    );
    _focusNode.requestFocus();
  }

  void _prefixLine(String prefix) {
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final cursor = sel.isValid ? sel.start : text.length;
    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final nextText = text.replaceRange(lineStart, lineStart, prefix);
    final nextCursor = cursor + prefix.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
    _focusNode.requestFocus();
  }

  void _insertLink() {
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final label = selected.isEmpty ? 'text' : selected;
    const url = 'https://';
    final replacement = '[$label]($url)';
    final nextText = text.replaceRange(start, end, replacement);
    final urlStart = start + label.length + 3;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + url.length,
      ),
    );
    _focusNode.requestFocus();
  }

  /// Keyboard-shortcut wrapper: wraps the active selection, exits an existing
  /// closing delimiter if the cursor sits right before it, or inserts empty
  /// delimiters with the cursor placed inside for immediate typing.
  void _applyWrapShortcut(String prefix, String suffix) {
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(start, end);
      final nextText = text.replaceRange(start, end, '$prefix$selected$suffix');
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selected.length,
        ),
      );
      return;
    }

    if (text.substring(start).startsWith(suffix)) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: start + suffix.length),
      );
      return;
    }

    final nextText = text.replaceRange(start, start, '$prefix$suffix');
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
  }

  void _applyLinkShortcut() {
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _insertLink();
      return;
    }
    final cursor = sel.isValid ? sel.start : text.length;
    const replacement = '[](https://)';
    final nextText = text.replaceRange(cursor, cursor, replacement);
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor + 1),
    );
  }

  Map<ShortcutActivator, VoidCallback> get _markdownShortcuts => {
    for (final ctrl in [true, false]) ...{
      SingleActivator(
        LogicalKeyboardKey.keyB,
        control: ctrl,
        meta: !ctrl,
      ): () => _applyWrapShortcut('**', '**'),
      SingleActivator(
        LogicalKeyboardKey.keyI,
        control: ctrl,
        meta: !ctrl,
      ): () => _applyWrapShortcut('*', '*'),
      SingleActivator(
        LogicalKeyboardKey.keyE,
        control: ctrl,
        meta: !ctrl,
      ): () => _applyWrapShortcut('`', '`'),
      SingleActivator(
        LogicalKeyboardKey.keyX,
        control: ctrl,
        meta: !ctrl,
        shift: true,
      ): () => _applyWrapShortcut('~~', '~~'),
      SingleActivator(
        LogicalKeyboardKey.keyK,
        control: ctrl,
        meta: !ctrl,
      ): _applyLinkShortcut,
      SingleActivator(
        LogicalKeyboardKey.enter,
        control: ctrl,
        meta: !ctrl,
      ): _handleSave,
    },
  };

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
                _ModeSwitch(
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
              _MarkdownToolbar(
                onBold: () => _wrapSelection('**', '**', 'bold'),
                onItalic: () => _wrapSelection('*', '*', 'italic'),
                onStrike: () => _wrapSelection('~~', '~~', 'text'),
                onHeading: () => _prefixLine('# '),
                onBullet: () => _prefixLine('- '),
                onQuote: () => _prefixLine('> '),
                onCode: () => _wrapSelection('`', '`', 'code'),
                onLink: _insertLink,
              ),
              const SizedBox(height: 10),
              CallbackShortcuts(
                bindings: _markdownShortcuts,
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
            Row(
              children: [
                if (hasInitial || _controller.text.isNotEmpty)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: () {
                          _controller.clear();
                          if (_previewMode) {
                            setState(() {});
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          l10n.translate('series_note_clear'),
                          style: AppTypography.sans(
                            color: c.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    l10n.translate('cancel'),
                    style: AppTypography.sans(
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.pillRadius,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.translate('save'),
                    style: AppTypography.sans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool previewMode;
  final String writeLabel;
  final String previewLabel;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({
    required this.previewMode,
    required this.writeLabel,
    required this.previewLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeTab(
            label: writeLabel,
            selected: !previewMode,
            onTap: () => onChanged(false),
          ),
          _ModeTab(
            label: previewLabel,
            selected: previewMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            color: selected ? c.onAccent : c.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MarkdownToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrike;
  final VoidCallback onHeading;
  final VoidCallback onBullet;
  final VoidCallback onQuote;
  final VoidCallback onCode;
  final VoidCallback onLink;

  const _MarkdownToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onStrike,
    required this.onHeading,
    required this.onBullet,
    required this.onQuote,
    required this.onCode,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.format_bold_rounded,
            tooltip: 'Bold',
            onTap: onBold,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.format_italic_rounded,
            tooltip: 'Italic',
            onTap: onItalic,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.format_strikethrough_rounded,
            tooltip: 'Strikethrough',
            onTap: onStrike,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.title_rounded,
            tooltip: 'Heading',
            onTap: onHeading,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'List',
            onTap: onBullet,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.format_quote_rounded,
            tooltip: 'Quote',
            onTap: onQuote,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.code_rounded,
            tooltip: 'Code',
            onTap: onCode,
            color: c.textMuted,
          ),
          _ToolbarButton(
            icon: Icons.link_rounded,
            tooltip: 'Link',
            onTap: onLink,
            color: c.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
