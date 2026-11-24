import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_refresh_indicator.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list_sort.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_tile.dart';
import 'package:mangabaka_app/features/lists/widgets/list_search_field.dart';
import 'package:mangabaka_app/features/lists/widgets/list_toolbar.dart';
import 'package:mangabaka_app/features/lists/widgets/lists_selection_bar.dart';

/// Search, sort and the rows of every list, with multi-select over a floating bar.
class LibraryListsPane extends StatelessWidget {
  final LibraryListsController lists;
  final LibraryListFlows flows;
  final ValueChanged<LibraryList> onOpen;
  final int? activeId;

  /// Space kept clear under the last row, for a floating action button.
  final double bottomInset;

  const LibraryListsPane({
    super.key,
    required this.lists,
    required this.flows,
    required this.onOpen,
    this.activeId,
    this.bottomInset = 96,
  });

  Future<void> _refresh(BuildContext context) async {
    final error = await lists.refresh();
    if (error != null && context.mounted) {
      AppSnackBar.show(
        context,
        LocalizationService().translate(error),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: lists,
      builder: (context, _) {
        final visible = lists.visible;
        final selecting = lists.isSelecting;
        final selected = lists.selected;
        final anyPrivate = lists.all.any(
          (l) => selected.contains(l.id) && l.isPrivate,
        );
        final anyPublic = lists.all.any(
          (l) => selected.contains(l.id) && !l.isPrivate,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListToolbar<LibraryListSort>(
              search: ListSearchField(
                hint: l10n.translate('lists_search'),
                initial: lists.query,
                onChanged: lists.setQuery,
              ),
              sortLabel: l10n.translate('sort_by'),
              sort: lists.sort,
              sortOptions: [
                for (final s in LibraryListSort.values)
                  (s, l10n.translate(s.labelKey)),
              ],
              onSort: lists.setSort,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MbRefreshIndicator(
                      onRefresh: () => _refresh(context),
                      child: _body(context, l10n, visible),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ListsSelectionBar(
                      visible: selecting,
                      count: selected.length,
                      busy: selected.any(lists.isBusy),
                      onClose: lists.clearSelection,
                      onSelectAll: () =>
                          lists.selectAll(visible.map((l) => l.id)),
                      actions: [
                        SelectionAction(
                          icon: Icons.lock_rounded,
                          label: l10n.translate('lists_make_private'),
                          onPressed: anyPublic
                              ? () => flows.setSelectedPrivate(
                                  context,
                                  isPrivate: true,
                                )
                              : null,
                        ),
                        SelectionAction(
                          icon: Icons.public_rounded,
                          label: l10n.translate('lists_make_public'),
                          onPressed: anyPrivate
                              ? () => flows.setSelectedPrivate(
                                  context,
                                  isPrivate: false,
                                )
                              : null,
                        ),
                        SelectionAction(
                          icon: Icons.delete_outline_rounded,
                          label: l10n.translate('lists_delete'),
                          destructive: true,
                          onPressed: () => flows.deleteSelected(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    LocalizationService l10n,
    List<LibraryList> visible,
  ) {
    if (!lists.isLoaded) {
      return const _Scrollable(child: Center(child: MbSpinner()));
    }
    if (visible.isEmpty) {
      return _Scrollable(
        child: _Message(
          icon: lists.all.isEmpty
              ? Icons.format_list_bulleted_rounded
              : Icons.search_off_rounded,
          text: l10n.translate(
            lists.all.isEmpty ? 'lists_empty' : 'no_results',
          ),
        ),
      );
    }
    final selecting = lists.isSelecting;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 4, bottom: bottomInset),
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final list = visible[i];
        return LibraryListTile(
          key: ValueKey('list_tile_${list.id}'),
          list: list,
          count: lists.countOf(list.id),
          selecting: selecting,
          selected: lists.selected.contains(list.id),
          active: !selecting && list.id == activeId,
          busy: lists.isBusy(list.id),
          onTap: () => selecting ? lists.toggleSelected(list.id) : onOpen(list),
          onLongPress: () => lists.toggleSelected(list.id),
          onMore: (anchor) => flows.showMenu(context, list, anchor: anchor),
        );
      },
    );
  }
}

/// Keeps pull-to-refresh working when there are no rows to scroll.
class _Scrollable extends StatelessWidget {
  final Widget child;

  const _Scrollable({required this.child});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: c.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
