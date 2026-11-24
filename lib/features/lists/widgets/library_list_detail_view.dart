import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/browse/models/sort_options.dart';
import 'package:mangabaka_app/features/library/widgets/library_grid_list.dart';
import 'package:mangabaka_app/features/lists/controllers/library_list_detail_controller.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/widgets/list_search_field.dart';
import 'package:mangabaka_app/features/lists/widgets/list_toolbar.dart';
import 'package:mangabaka_app/features/lists/widgets/lists_selection_bar.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';

/// The series on one list. The owner supplies the header; this is toolbar, grid and selection.
class LibraryListDetailView extends StatelessWidget {
  final LibraryListDetailController controller;
  final ScrollController scrollController;
  final SeriesListDeps deps;
  final ValueChanged<api.Series> onOpenSeries;
  final VoidCallback onAddSeries;
  final EdgeInsetsGeometry toolbarPadding;

  const LibraryListDetailView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.deps,
    required this.onOpenSeries,
    required this.onAddSeries,
    this.toolbarPadding = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  static Map<String, String> sortOptions(LocalizationService l10n) => {
    ...searchSortOptions(l10n, library: true)..remove('random'),
    'created_at': l10n.translate('lists_sort_recently_added'),
  };

  Future<void> _removeSelected(BuildContext context) async {
    final l10n = LocalizationService();
    final count = controller.selected.length;
    final error = await controller.removeSelected();
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      error != null
          ? l10n.translate(error)
          : l10n
                .translate('lists_removed_many')
                .replaceAll('{count}', '$count'),
      isError: error != null,
    );
  }

  void _tap(api.Series series) {
    if (controller.isSelecting) {
      controller.toggle(series.id);
    } else {
      onOpenSeries(series);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final sorts = sortOptions(l10n);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListToolbar<String>(
              padding: toolbarPadding,
              search: ListSearchField(
                key: ValueKey('list_search_${controller.listId}'),
                hint: l10n.translate('lists_search_series'),
                initial: controller.query,
                onChanged: controller.setQuery,
              ),
              sortLabel: l10n.translate('sort_by'),
              sort: controller.sortBy,
              sortOptions: [for (final e in sorts.entries) (e.key, e.value)],
              onSort: controller.setSort,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LibraryGridList(
                      items: items,
                      tabKey: 'list_${controller.listId}',
                      scrollController: scrollController,
                      onRefresh: controller.lists.syncAll,
                      onItemTap: _tap,
                      onItemLongPress: (s) => controller.toggle(s.id),
                      selectedIds: controller.selected,
                      deps: deps,
                      empty: controller.total == 0
                          ? _EmptyList(onAdd: onAddSeries)
                          : null,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ListsSelectionBar(
                      visible: controller.isSelecting,
                      count: controller.selected.length,
                      busy: controller.isBusy,
                      onClose: controller.clearSelection,
                      onSelectAll: controller.selectAll,
                      actions: [
                        SelectionAction(
                          icon: Icons.playlist_remove_rounded,
                          label: l10n.translate('lists_remove_from_list'),
                          destructive: true,
                          onPressed: () => _removeSelected(context),
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
}

class _EmptyList extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyList({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_rounded, size: 48, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.translate('lists_empty_series'),
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: c.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 20),
            MbSecondaryButton(
              expand: false,
              icon: Icons.playlist_add_rounded,
              label: l10n.translate('lists_add_series'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
