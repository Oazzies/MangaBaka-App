import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/network/paged_list.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/add_to_stack_sheet.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_card.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';

/// The series page's Stacks tab: the most-voted public stacks that include
/// the series, and a way to put it in one of the reader's own.
class SeriesStacksTab extends StatefulWidget {
  final Series series;
  final double horizontalPadding;

  /// How many stacks the tab shows before "See all".
  static const int previewCount = 12;

  const SeriesStacksTab({
    super.key,
    required this.series,
    this.horizontalPadding = 16,
  });

  @override
  State<SeriesStacksTab> createState() => _SeriesStacksTabState();
}

class _SeriesStacksTabState extends State<SeriesStacksTab> {
  final LocalizationService _l10n = LocalizationService();
  late Future<PagedList<StackSummary>> _stacks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SeriesStacksTab old) {
    super.didUpdateWidget(old);
    if (old.series.id != widget.series.id) _load();
  }

  void _load() {
    _stacks = getIt<StackService>()
        .forSeries(widget.series.id, limit: SeriesStacksTab.previewCount)
        .then((page) {
          getIt<StackStatusController>().request(page.items.map((s) => s.id));
          return page;
        });
  }

  void _seeAll() => StacksListScreen.open(
    context,
    StacksListSource.series(widget.series.id, widget.series.title),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _l10n.translate('stacks_series_tab_intro'),
                  style: AppTypography.sans(
                    color: c.textMuted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              MbPrimaryButton(
                label: _l10n.translate('stacks_add_to_short'),
                expand: false,
                icon: Icons.playlist_add_rounded,
                onPressed: () async {
                  await showAddToStackSheet(context, widget.series);
                  if (mounted) setState(_load);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<PagedList<StackSummary>>(
            future: _stacks,
            builder: (context, snap) {
              if (snap.hasError) {
                return _message(
                  stackErrorMessage(snap.error!, _l10n),
                  action: TextButton(
                    onPressed: () => setState(_load),
                    child: Text(_l10n.translate('retry')),
                  ),
                );
              }
              final loading = snap.connectionState != ConnectionState.done;
              final stacks = snap.data?.items ?? const <StackSummary>[];
              if (!loading && stacks.isEmpty) {
                return _message(_l10n.translate('stacks_series_none'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _grid(context, stacks, loading),
                  if (snap.data?.hasNext ?? false)
                    Align(
                      child: TextButton.icon(
                        onPressed: _seeAll,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(_l10n.translate('view_all')),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// A plain wrap of fixed-width cards: the tab sits inside the page's own
  /// scroll view, so it must not scroll itself.
  Widget _grid(BuildContext context, List<StackSummary> stacks, bool loading) {
    final desktop = DesktopLayout.isActive(context);
    const spacing = 14.0;
    final maxTile = desktop ? 220.0 : 180.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = math.max(
          2,
          ((width + spacing) / (maxTile + spacing)).ceil(),
        );
        final tile = (width - spacing * (columns - 1)) / columns;
        final count = loading && stacks.isEmpty ? columns : stacks.length;
        return Wrap(
          spacing: spacing,
          runSpacing: 22,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: tile,
                height: StackCard.heightFor(context, tile),
                child: stacks.isEmpty
                    ? const StackCardSkeleton()
                    : StackCard(stack: stacks[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _message(String text, {Widget? action}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(Icons.layers_outlined, size: 40, color: context.colors.textMuted),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 14,
          ),
        ),
        ?action,
      ],
    ),
  );
}
