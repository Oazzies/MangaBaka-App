import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Markdown text-editing helpers and keyboard shortcuts for [NoteEditorDialog].
class NoteMarkdownHelper {
  static void wrapSelection(
    TextEditingController controller,
    FocusNode focusNode,
    String prefix,
    String suffix,
    String placeholder,
  ) {
    final value = controller.value;
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
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
    );
    focusNode.requestFocus();
  }

  static void prefixLine(
    TextEditingController controller,
    FocusNode focusNode,
    String prefix,
  ) {
    final value = controller.value;
    final text = value.text;
    final sel = value.selection;
    final cursor = sel.isValid ? sel.start : text.length;
    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final nextText = text.replaceRange(lineStart, lineStart, prefix);
    final nextCursor = cursor + prefix.length;
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
    focusNode.requestFocus();
  }

  static void insertLink(
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    final value = controller.value;
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
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + url.length,
      ),
    );
    focusNode.requestFocus();
  }

  /// Keyboard-shortcut wrapper: wraps the active selection, exits an existing
  /// closing delimiter if the cursor sits right before it, or inserts empty
  /// delimiters with the cursor placed inside for immediate typing.
  static void applyWrapShortcut(
    TextEditingController controller,
    String prefix,
    String suffix,
  ) {
    final value = controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (sel.isValid && !sel.isCollapsed) {
      final selected = text.substring(start, end);
      final nextText = text.replaceRange(start, end, '$prefix$selected$suffix');
      controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selected.length,
        ),
      );
      return;
    }

    if (text.substring(start).startsWith(suffix)) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: start + suffix.length),
      );
      return;
    }

    final nextText = text.replaceRange(start, start, '$prefix$suffix');
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
  }

  static void applyLinkShortcut(
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    final value = controller.value;
    final text = value.text;
    final sel = value.selection;
    if (sel.isValid && !sel.isCollapsed) {
      insertLink(controller, focusNode);
      return;
    }
    final cursor = sel.isValid ? sel.start : text.length;
    const replacement = '[](https://)';
    final nextText = text.replaceRange(cursor, cursor, replacement);
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor + 1),
    );
  }

  static Map<ShortcutActivator, VoidCallback> buildShortcuts(
    TextEditingController controller,
    FocusNode focusNode,
    VoidCallback onSave,
  ) => {
    for (final ctrl in [true, false]) ...{
      SingleActivator(LogicalKeyboardKey.keyB, control: ctrl, meta: !ctrl):
          () => applyWrapShortcut(controller, '**', '**'),
      SingleActivator(LogicalKeyboardKey.keyI, control: ctrl, meta: !ctrl):
          () => applyWrapShortcut(controller, '*', '*'),
      SingleActivator(LogicalKeyboardKey.keyE, control: ctrl, meta: !ctrl):
          () => applyWrapShortcut(controller, '`', '`'),
      SingleActivator(
        LogicalKeyboardKey.keyX,
        control: ctrl,
        meta: !ctrl,
        shift: true,
      ): () => applyWrapShortcut(controller, '~~', '~~'),
      SingleActivator(LogicalKeyboardKey.keyK, control: ctrl, meta: !ctrl):
          () => applyLinkShortcut(controller, focusNode),
      SingleActivator(LogicalKeyboardKey.enter, control: ctrl, meta: !ctrl):
          onSave,
    },
  };
}
