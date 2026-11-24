import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/lists/controllers/library_list_detail_controller.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_detail_view.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// One list on a phone. On wider screens the same view sits beside the lists.
class LibraryListScreen extends StatefulWidget {
  final LibraryListsController lists;
  final LibraryListFlows flows;
  final int listId;
  final SeriesListDeps deps;

  const LibraryListScreen({
    super.key,
    required this.lists,
    required this.flows,
    required this.listId,
    required this.deps,
  });

  static Future<void> open(
    BuildContext context, {
    required LibraryListsController lists,
    required LibraryListFlows flows,
    required int listId,
    required SeriesListDeps deps,
  }) => Navigator.of(context).push(
    AppTransitions.slideRight(
      LibraryListScreen(lists: lists, flows: flows, listId: listId, deps: deps),
    ),
  );

  @override
  State<LibraryListScreen> createState() => _LibraryListScreenState();
}

class _LibraryListScreenState extends State<LibraryListScreen> {
  late final LibraryListDetailController _detail = LibraryListDetailController(
    lists: widget.lists,
    listId: widget.listId,
  );
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _detail.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openSeries(api.Series series) => Navigator.of(context).push(
    AppTransitions.slideUp(
      SeriesDetailScreen(series: series, heroTagPrefix: 'library'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      // The detail too: its selection decides whether Back pops or clears.
      listenable: Listenable.merge([widget.lists, _detail]),
      builder: (context, _) {
        final list = _detail.list;
        return PopScope(
          canPop: !_detail.isSelecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _detail.clearSelection();
          },
          child: Scaffold(
            backgroundColor: context.colors.background,
            appBar: mbScreenAppBar(
              title: list?.name ?? l10n.translate('lists'),
              actions: [
                if (list != null) ...[
                  IconButton(
                    tooltip: l10n.translate('lists_add_series'),
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () => widget.flows.addSeries(context, list),
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: l10n.translate('more_options'),
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => widget.flows.showMenu(
                        context,
                        list,
                        anchor: globalRectOf(context),
                        onDeleted: () {
                          if (mounted) Navigator.of(this.context).pop();
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
              ],
            ),
            body: list == null
                ? _Gone(text: l10n.translate('lists_error_gone'))
                : SafeArea(
                    top: false,
                    bottom: false,
                    child: LibraryListDetailView(
                      controller: _detail,
                      scrollController: _scroll,
                      deps: widget.deps,
                      onOpenSeries: _openSeries,
                      onAddSeries: () => widget.flows.addSeries(context, list),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _Gone extends StatelessWidget {
  final String text;

  const _Gone({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 16,
        ),
      ),
    ),
  );
}
