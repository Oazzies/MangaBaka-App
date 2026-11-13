import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Write / Preview segmented toggle for the note editor header.
class NoteEditorModeSwitch extends StatelessWidget {
  final bool previewMode;
  final String writeLabel;
  final String previewLabel;
  final ValueChanged<bool> onChanged;

  const NoteEditorModeSwitch({
    super.key,
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

/// Horizontal Markdown formatting toolbar for the note editor.
class NoteMarkdownToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrike;
  final VoidCallback onHeading;
  final VoidCallback onBullet;
  final VoidCallback onQuote;
  final VoidCallback onCode;
  final VoidCallback onLink;

  const NoteMarkdownToolbar({
    super.key,
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

/// Bottom action row (Clear, Cancel, Save) for [NoteEditorDialog].
class NoteEditorActionsRow extends StatelessWidget {
  final TextEditingController controller;
  final bool hasInitial;
  final LocalizationService l10n;
  final VoidCallback onCleared;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const NoteEditorActionsRow({
    super.key,
    required this.controller,
    required this.hasInitial,
    required this.l10n,
    required this.onCleared,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        if (hasInitial || controller.text.isNotEmpty)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: onCleared,
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
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          onPressed: onSave,
          style: FilledButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.translate('save'),
            style: AppTypography.sans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
