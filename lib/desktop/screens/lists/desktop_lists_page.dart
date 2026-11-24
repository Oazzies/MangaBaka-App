import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/date_utils.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list_sort.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';
import 'package:mangabaka_app/features/lists/widgets/list_search_field.dart';
import 'package:mangabaka_app/features/lists/widgets/lists_selection_bar.dart';

part 'desktop_lists_table_part.dart';

/// Every list as a table, for renaming, privacy and deleting in bulk.
class DesktopListsPage extends StatefulWidget {
  final LibraryListsController lists;
  final LibraryListFlows flows;

  /// Opens the library scoped to the list.
  final ValueChanged<int> onOpenList;

  const DesktopListsPage({
    super.key,
    required this.lists,
    required this.flows,
    required this.onOpenList,
  });

  @override
  State<DesktopListsPage> createState() => _DesktopListsPageState();
}

class _DesktopListsPageState extends State<DesktopListsPage> {
  LibraryListsController get _lists => widget.lists;

  @override
  void initState() {
    super.initState();
    _lists.refresh();
  }

  @override
  void dispose() {
    // The controller outlives the page and its selection belongs to the page, but
    // listeners must not hear about it while the tree is being torn down.
    final lists = _lists;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      lists
        ..clearSelection()
        ..setQuery('');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: _lists,
      builder: (context, _) {
        final visible = _lists.visible;
        final selected = _lists.selected;
        final anyPrivate = _lists.all.any(
          (l) => selected.contains(l.id) && l.isPrivate,
        );
        final anyPublic = _lists.all.any(
          (l) => selected.contains(l.id) && !l.isPrivate,
        );
        return Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopPageHeader(
                leading: DesktopIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: l10n.translate('back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: l10n.translate('lists'),
                subtitle: _lists.isLoaded
                    ? l10n
                          .translate(
                            _lists.all.length == 1
                                ? 'lists_count_one'
                                : 'lists_count',
                          )
                          .replaceAll(
                            '{count}',
                            NumberUtils.formatCount(_lists.all.length),
                          )
                    : null,
                actions: [
                  DesktopPillButton(
                    key: const ValueKey('desktop_lists_page_new'),
                    label: l10n.translate('lists_new'),
                    icon: Icons.add_rounded,
                    primary: true,
                    onPressed: () => widget.flows.create(context),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesktopTokens.pagePadding,
                  0,
                  DesktopTokens.pagePadding,
                  12,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: ListSearchField(
                          hint: l10n.translate('lists_search'),
                          initial: _lists.query,
                          onChanged: _lists.setQuery,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MbDropdown<LibraryListSort>(
                      label: l10n.translate('sort_by'),
                      icon: Icons.sort_rounded,
                      value: _lists.sort,
                      options: [
                        for (final s in LibraryListSort.values)
                          (s, l10n.translate(s.labelKey)),
                      ],
                      onChanged: _lists.setSort,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _body(context, l10n, visible)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: ListsSelectionBar(
                        visible: _lists.isSelecting,
                        count: selected.length,
                        busy: selected.any(_lists.isBusy),
                        onClose: _lists.clearSelection,
                        actions: [
                          SelectionAction(
                            icon: Icons.lock_rounded,
                            label: l10n.translate('lists_make_private'),
                            onPressed: anyPublic
                                ? () => widget.flows.setSelectedPrivate(
                                    context,
                                    isPrivate: true,
                                  )
                                : null,
                          ),
                          SelectionAction(
                            icon: Icons.public_rounded,
                            label: l10n.translate('lists_make_public'),
                            onPressed: anyPrivate
                                ? () => widget.flows.setSelectedPrivate(
                                    context,
                                    isPrivate: false,
                                  )
                                : null,
                          ),
                          SelectionAction(
                            icon: Icons.delete_outline_rounded,
                            label: l10n.translate('lists_delete'),
                            destructive: true,
                            onPressed: () =>
                                widget.flows.deleteSelected(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    LocalizationService l10n,
    List<LibraryList> visible,
  ) {
    if (!_lists.isLoaded) return const Center(child: MbSpinner());
    if (_lists.all.isEmpty) {
      return DesktopEmptyState(
        icon: Icons.format_list_bulleted_rounded,
        message: l10n.translate('lists_empty'),
        action: DesktopPillButton(
          label: l10n.translate('lists_new'),
          icon: Icons.add_rounded,
          primary: true,
          onPressed: () => widget.flows.create(context),
        ),
      );
    }
    if (visible.isEmpty) {
      return DesktopEmptyState(
        icon: Icons.search_off_rounded,
        message: l10n.translate('no_results'),
      );
    }
    final allSelected = visible.every((l) => _lists.selected.contains(l.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(
          allSelected: allSelected,
          onToggleAll: () => allSelected
              ? _lists.clearSelection()
              : _lists.selectAll(visible.map((l) => l.id)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              DesktopTokens.pagePadding - 8,
              0,
              DesktopTokens.pagePadding - 8,
              96,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final list = visible[i];
              return _TableRow(
                key: ValueKey('desktop_lists_row_${list.id}'),
                list: list,
                count: _lists.countOf(list.id),
                selected: _lists.selected.contains(list.id),
                busy: _lists.isBusy(list.id),
                onToggle: () => _lists.toggleSelected(list.id),
                onOpen: () => widget.onOpenList(list.id),
                onMenu: (anchor) =>
                    widget.flows.showMenu(context, list, anchor: anchor),
              );
            },
          ),
        ),
      ],
    );
  }
}
