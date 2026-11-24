import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';

class LibraryListTile extends StatelessWidget {
  final LibraryList list;
  final int count;
  final bool selecting;
  final bool selected;

  /// The list shown beside the master pane on wide screens.
  final bool active;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<Rect?>? onMore;

  const LibraryListTile({
    super.key,
    required this.list,
    required this.count,
    required this.onTap,
    this.selecting = false,
    this.selected = false,
    this.active = false,
    this.busy = false,
    this.onLongPress,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    final highlight = selected || active;
    final meta = [
      l10n
          .translate('series_count')
          .replaceAll('{count}', NumberUtils.formatCount(count)),
      if (list.isPrivate) l10n.translate('lists_private'),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: highlight ? c.surfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? c.accent : c.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlight ? c.border : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    selecting
                        ? (selected
                              ? Icons.check_rounded
                              : Icons.circle_outlined)
                        : (list.isPrivate
                              ? Icons.lock_rounded
                              : Icons.format_list_bulleted_rounded),
                    size: 20,
                    color: selected ? c.onAccent : c.textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: busy
                      ? const Center(child: MbSpinner(size: 18))
                      : (onMore != null && !selecting)
                      ? Builder(
                          builder: (context) => IconButton(
                            tooltip: l10n.translate('more_options'),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: c.textMuted,
                            ),
                            onPressed: () => onMore!(globalRectOf(context)),
                          ),
                        )
                      : Icon(Icons.chevron_right_rounded, color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
