import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_editor_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';

class StackEditorEntryRow extends StatelessWidget {
  final int index;
  final EditableStackEntry entry;
  final int count;
  final bool desktop;
  final VoidCallback onNote;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;
  final VoidCallback? onReplace;

  const StackEditorEntryRow({
    super.key,
    required this.index,
    required this.entry,
    required this.count,
    required this.desktop,
    required this.onNote,
    required this.onRemove,
    required this.onMove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final series = entry.series;
    final note = entry.note.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.unavailable
              ? c.warning.withValues(alpha: 0.5)
              : c.border,
        ),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
                child: Icon(Icons.drag_indicator_rounded, color: c.textMuted),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '#${index + 1}',
              style: AppTypography.display(color: c.accent, fontSize: 15),
            ),
          ),
          MbCover(
            url: series?.coverUrl ?? '',
            width: 42,
            radius: 6,
            memCacheWidth: 96,
            blurred: WidgetUtils.isRatingBlurred(series?.contentRating ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                if (entry.unavailable)
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: c.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.translate(
                            entry.issue == StackEntryIssue.deleted
                                ? 'stacks_entry_deleted'
                                : 'stacks_entry_merged',
                          ),
                          style: AppTypography.sans(
                            color: c.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (onReplace != null)
                        TextButton(
                          onPressed: onReplace,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.translate('stacks_entry_replace')),
                        ),
                    ],
                  )
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNote,
                    child: note.isEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_comment_outlined,
                                size: 14,
                                color: c.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.translate('stacks_note_add'),
                                style: AppTypography.sans(
                                  color: c.accent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 2.5,
                                  decoration: BoxDecoration(
                                    color: c.accent.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.sans(
                                      color: c.textMuted,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),
          ),
          if (desktop) ...[
            IconButton(
              tooltip: l10n.translate('stacks_move_up'),
              icon: Icon(Icons.keyboard_arrow_up_rounded, color: c.textMuted),
              onPressed: index == 0 ? null : () => onMove(-1),
            ),
            IconButton(
              tooltip: l10n.translate('stacks_move_down'),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted),
              onPressed: index == count - 1 ? null : () => onMove(1),
            ),
            IconButton(
              tooltip: l10n.translate('stacks_remove'),
              icon: Icon(Icons.close_rounded, color: c.textMuted, size: 20),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
