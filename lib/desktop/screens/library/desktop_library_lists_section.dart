import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';

/// The library side panel's lists: picking one scopes the library to it.
class DesktopLibraryListsSection extends StatelessWidget {
  final LibraryListsController lists;
  final LibraryListFlows flows;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onManage;

  const DesktopLibraryListsSection({
    super.key,
    required this.lists,
    required this.flows,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final sorted = [...lists.all]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate('lists').toUpperCase(),
                  style: AppTypography.display(color: c.text, fontSize: 17),
                ),
              ),
              DesktopIconButton(
                key: const ValueKey('desktop_lists_new'),
                icon: Icons.add_rounded,
                size: 18,
                tooltip: l10n.translate('lists_new'),
                onPressed: onCreate,
              ),
              DesktopIconButton(
                key: const ValueKey('desktop_lists_manage'),
                icon: Icons.tune_rounded,
                size: 18,
                tooltip: l10n.translate('lists_manage'),
                onPressed: onManage,
              ),
            ],
          ),
        ),
        if (!lists.isLoaded)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: MbSpinner(size: 18)),
          )
        else if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Text(
              l10n.translate('lists_empty'),
              style: AppTypography.sans(color: c.textMuted, fontSize: 13),
            ),
          )
        else
          for (final list in sorted)
            _ListRow(
              key: ValueKey('desktop_list_row_${list.id}'),
              list: list,
              count: lists.countOf(list.id),
              selected: list.id == selectedId,
              onTap: () => onSelect(list.id),
              onMenu: (anchor) => flows.showMenu(context, list, anchor: anchor),
            ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final LibraryList list;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Rect?> onMenu;

  const _ListRow({
    super.key,
    required this.list,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Builder(
        builder: (context) => DesktopHoverSurface(
          onTap: onTap,
          onSecondaryTap: () => onMenu(globalRectOf(context)),
          selected: selected,
          selectedColor: c.surfaceRaised,
          hoverColor: c.surface,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                list.isPrivate
                    ? Icons.lock_rounded
                    : Icons.format_list_bulleted_rounded,
                size: 17,
                color: selected ? c.accent : c.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: selected ? c.text : c.text.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                NumberUtils.formatCount(count),
                style: AppTypography.sans(
                  color: selected ? c.accent : c.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
