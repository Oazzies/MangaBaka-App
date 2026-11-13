import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_editor_entry_row.dart';

class StackEditorEntriesPane extends StatelessWidget {
  final StackEditorController controller;
  final LocalizationService l10n;
  final double pad;
  final bool showAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditNote;
  final ValueChanged<int> onReplaceMerged;

  const StackEditorEntriesPane({
    super.key,
    required this.controller,
    required this.l10n,
    required this.pad,
    this.showAdd = true,
    required this.onAdd,
    required this.onEditNote,
    required this.onReplaceMerged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final desktop = DesktopLayout.isActive(context);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n
                  .translate('stacks_entries_count')
                  .replaceAll('{n}', '${controller.entries.length}')
                  .replaceAll('{max}', '${StackLimits.entriesMax}'),
              style: AppTypography.sans(color: c.textMuted, fontSize: 13),
            ),
          ),
          if (showAdd)
            MbPrimaryButton(
              label: l10n.translate('stacks_add_series'),
              expand: false,
              icon: Icons.add_rounded,
              onPressed: controller.entries.length >= StackLimits.entriesMax
                  ? null
                  : onAdd,
            ),
        ],
      ),
    );

    if (controller.entries.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.playlist_add_rounded,
                      size: 44,
                      color: c.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n
                          .translate('stacks_editor_empty')
                          .replaceAll('{n}', '${StackLimits.publishMin}'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sans(
                        color: c.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.fromLTRB(pad, 0, pad, 48),
            buildDefaultDragHandles: false,
            itemCount: controller.entries.length,
            onReorderItem: controller.reorder,
            itemBuilder: (context, i) {
              final e = controller.entries[i];
              final row = StackEditorEntryRow(
                index: i,
                entry: e,
                count: controller.entries.length,
                desktop: desktop,
                onNote: () => onEditNote(i),
                onRemove: () => controller.removeAt(i),
                onMove: (d) => controller.move(i, d),
                onReplace: e.mergedWith == null
                    ? null
                    : () => onReplaceMerged(i),
              );
              if (desktop) return KeyedSubtree(key: e.key, child: row);
              return Dismissible(
                key: e.key,
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: c.error),
                ),
                onDismissed: (_) => controller.removeAt(i),
                child: row,
              );
            },
          ),
        ),
      ],
    );
  }
}
