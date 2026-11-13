import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_detail_components.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_note_mark.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_note_text.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Builds the ranked entry slivers (loading, error, spoiler gate, grid/list)
/// for [StackDetailScreen].
List<Widget> buildStackDetailEntrySlivers(
  BuildContext context, {
  required StackSummary summary,
  required StackDetail? detail,
  required AsyncSnapshot<StackDetail> snapshot,
  required bool isOwner,
  required bool spoilersRevealed,
  required StackEntrySort sort,
  required LocalizationService l10n,
  required VoidCallback onRetry,
  required VoidCallback onEdit,
  required VoidCallback onRevealSpoilers,
  required ValueChanged<StackEntrySort> onSortChanged,
  double sidePadding = AppConstants.horizontalPadding,
}) {
  final pad = EdgeInsets.symmetric(horizontal: sidePadding);
  if (detail == null) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: snapshot.hasError
              ? StackErrorState(error: snapshot.error!, onRetry: onRetry)
              : const Center(child: MbSpinner()),
        ),
      ),
    ];
  }

  final toolbar = SliverPadding(
    padding: pad.copyWith(top: 8, bottom: 12),
    sliver: SliverToBoxAdapter(
      child: _StackEntriesToolbar(
        l10n: l10n,
        sort: sort,
        onSortChanged: onSortChanged,
      ),
    ),
  );

  if (detail.entries.isEmpty) {
    return [
      toolbar,
      SliverToBoxAdapter(
        child: StackEmptyEntries(isOwner: isOwner, onEdit: onEdit),
      ),
    ];
  }

  if (summary.isSpoiler && !spoilersRevealed && !isOwner) {
    return [
      toolbar,
      SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: StackSpoilerGate(onReveal: onRevealSpoilers),
        ),
      ),
    ];
  }

  return [
    toolbar,
    ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) {
        final style = SettingsManager().resolvedStacksListStyle;
        final columns = SettingsManager().resolvedStacksGridColumnCount;
        final entries = _sortEntries(detail.entries, sort);
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final prefix = 'stack_${detail.id}';
        void open(Series s) => Navigator.of(context).push(
          AppTransitions.slideUp(
            SeriesDetailScreen(series: s, heroTagPrefix: prefix),
          ),
        );

        if (style.isGrid) {
          final desktop = DesktopLayout.isActive(context);
          return SliverPadding(
            padding: pad,
            sliver: SliverGrid(
              gridDelegate: columns > 0
                  ? SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: style.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    )
                  : SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: desktop ? 190 : 160,
                      childAspectRatio: style.childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final e = entries[i];
                final series = e.series;
                if (series == null) {
                  return StackPlaceholderTile(entry: e, compact: true);
                }
                return MbEntrance(
                  index: i,
                  child: LayoutBuilder(
                    builder: (context, tileConstraints) => Stack(
                      children: [
                        Positioned.fill(
                          child: MbTappable(
                            pressedScale: 0.98,
                            onTap: () => open(series),
                            onLongPress: e.note == null || landscape
                                ? null
                                : () => _showStackNoteSheet(context, e),
                            child: EntryListItem(
                              key: ValueKey('${style.name}_${series.id}'),
                              series: series,
                              ranking: e.rank,
                              heroTagPrefix: prefix,
                              listStyle: style,
                            ),
                          ),
                        ),
                        if (e.note != null)
                          Positioned(
                            right: 6,
                            bottom: style == AppListStyle.compactGrid
                                ? tileConstraints.maxHeight -
                                      tileConstraints.maxWidth / 0.65 +
                                      6
                                : 6,
                            child: StackNoteMark(
                              note: e.note!,
                              hover: landscape,
                              onTap: () => _showStackNoteSheet(context, e),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }, childCount: entries.length),
            ),
          );
        }

        return SliverPadding(
          padding: pad,
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = entries[i];
              final series = e.series;
              if (series == null) return StackPlaceholderTile(entry: e);
              return MbEntrance(
                index: i,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MbTappable(
                      pressedScale: 0.98,
                      onTap: () => open(series),
                      child: EntryListItem(
                        key: ValueKey('${style.name}_${series.id}'),
                        series: series,
                        ranking: e.rank,
                        heroTagPrefix: prefix,
                        listStyle: style,
                      ),
                    ),
                    if (e.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: StackNoteText(note: e.note!),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  ];
}

List<StackEntry> _sortEntries(List<StackEntry> entries, StackEntrySort sort) {
  final list = [...entries];
  double rating(StackEntry e) => JsonUtils.toDouble(e.series?.rating) ?? -1;
  switch (sort) {
    case StackEntrySort.stackFirst:
      list.sort((a, b) => a.rank.compareTo(b.rank));
    case StackEntrySort.stackLast:
      list.sort((a, b) => b.rank.compareTo(a.rank));
    case StackEntrySort.ratingHigh:
      list.sort((a, b) => rating(b).compareTo(rating(a)));
    case StackEntrySort.ratingLow:
      list.sort((a, b) {
        final ra = rating(a), rb = rating(b);
        if (ra < 0 || rb < 0) return rb.compareTo(ra);
        return ra.compareTo(rb);
      });
  }
  return list;
}

void _showStackNoteSheet(BuildContext context, StackEntry entry) {
  showAdaptiveSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${entry.rank}  ${entry.series?.title ?? ''}',
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            StackNoteText(note: entry.note!, collapsedLines: 1000),
          ],
        ),
      ),
    ),
  );
}

class _StackEntriesToolbar extends StatelessWidget {
  final LocalizationService l10n;
  final StackEntrySort sort;
  final ValueChanged<StackEntrySort> onSortChanged;

  const _StackEntriesToolbar({
    required this.l10n,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = MbDropdown<StackEntrySort>(
      label: l10n.translate('sort_by'),
      icon: Icons.sort_rounded,
      value: sort,
      options: [
        for (final s in StackEntrySort.values) (s, l10n.translate(s.labelKey)),
      ],
      onChanged: onSortChanged,
    );
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (DesktopLayout.isActive(context))
          const DesktopListStyleToggle(scope: DesktopListScope.stacks),
        dropdown,
      ],
    );
  }
}
