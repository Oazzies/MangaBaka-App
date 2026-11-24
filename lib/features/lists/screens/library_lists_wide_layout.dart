import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/features/lists/controllers/library_list_detail_controller.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_detail_view.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/library_lists_pane.dart';
import 'package:mangabaka_app/features/lists/widgets/list_action_menu.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Tablets and narrow desktop windows: the lists on the left, the open one beside them.
class LibraryListsWideLayout extends StatelessWidget {
  static const double paneWidth = 360;

  final LibraryListsController lists;
  final LibraryListFlows flows;
  final LibraryListDetailController? detail;
  final SeriesListDeps deps;
  final ValueChanged<LibraryList> onOpen;

  const LibraryListsWideLayout({
    super.key,
    required this.lists,
    required this.flows,
    required this.detail,
    required this.deps,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: paneWidth,
          child: LibraryListsPane(
            lists: lists,
            flows: flows,
            activeId: detail?.listId,
            bottomInset: 24,
            onOpen: onOpen,
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: context.colors.border),
        Expanded(
          child: detail == null
              ? const SizedBox.shrink()
              : _DetailPane(
                  key: ValueKey('list_detail_${detail.listId}'),
                  lists: lists,
                  flows: flows,
                  detail: detail,
                  deps: deps,
                ),
        ),
      ],
    );
  }
}

/// Keyed by list, so each list gets its own scroll position.
class _DetailPane extends StatefulWidget {
  final LibraryListsController lists;
  final LibraryListFlows flows;
  final LibraryListDetailController detail;
  final SeriesListDeps deps;

  const _DetailPane({
    super.key,
    required this.lists,
    required this.flows,
    required this.detail,
    required this.deps,
  });

  @override
  State<_DetailPane> createState() => _DetailPaneState();
}

class _DetailPaneState extends State<_DetailPane> {
  final ScrollController _scroll = ScrollController();

  LibraryListsController get lists => widget.lists;
  LibraryListFlows get flows => widget.flows;
  LibraryListDetailController get detail => widget.detail;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openSeries(BuildContext context, api.Series series) =>
      Navigator.of(context).push(
        AppTransitions.slideUp(
          SeriesDetailScreen(series: series, heroTagPrefix: 'library'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return ListenableBuilder(
      listenable: lists,
      builder: (context, _) {
        final list = detail.list;
        if (list == null) return const SizedBox.shrink();
        final meta = [
          l10n
              .translate('series_count')
              .replaceAll(
                '{count}',
                NumberUtils.formatCount(lists.countOf(list.id)),
              ),
          if (list.isPrivate) l10n.translate('lists_private'),
        ].join(' · ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            color: c.text,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: AppTypography.sans(
                            color: c.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.translate('lists_add_series'),
                    icon: Icon(Icons.playlist_add_rounded, color: c.text),
                    onPressed: () => flows.addSeries(context, list),
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: l10n.translate('more_options'),
                      icon: Icon(Icons.more_vert_rounded, color: c.text),
                      onPressed: () => flows.showMenu(
                        context,
                        list,
                        anchor: globalRectOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LibraryListDetailView(
                controller: detail,
                scrollController: _scroll,
                deps: widget.deps,
                onOpenSeries: (s) => _openSeries(context, s),
                onAddSeries: () => flows.addSeries(context, list),
              ),
            ),
          ],
        );
      },
    );
  }
}
