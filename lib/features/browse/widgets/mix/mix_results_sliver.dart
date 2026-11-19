import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_row.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_state_views.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';

/// Listens to [SettingsManager] itself so a settings change rebuilds only this sliver.
class MixResultsSliver extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;
  final ValueChanged<Series> onSeriesTap;
  final SeriesListDeps deps;

  const MixResultsSliver({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onSeriesTap,
    required this.deps,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSeeds) {
      return _fill(MixEmptyState(l10n: l10n));
    }
    if (controller.results.isEmpty) {
      if (controller.isLoading) return _fill(MixLoadingState(l10n: l10n));
      if (controller.error != null) {
        return _fill(MixErrorState(l10n: l10n, onRetry: controller.refresh));
      }
      return _fill(MixNoResultsState(l10n: l10n));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) => _buildResults(context, SettingsManager()),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SettingsManager settings) {
    final style = settings.resolvedBrowseListStyle;

    final delegate = SliverChildBuilderDelegate((context, index) {
      final series = controller.results[index];
      return InkWell(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        onTap: () => onSeriesTap(series),
        child: EntryListItem(
          key: ValueKey('mix_${series.id}'),
          series: series,
          deps: deps,
        ),
      );
    }, childCount: controller.results.length);

    // List styles are rows; a grid delegate would squeeze them into cover-shaped cells.
    if (!style.isGrid) {
      final list = SliverList(delegate: delegate);
      if (!DesktopLayout.isActive(context)) return list;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: DesktopSeriesListHeader(style: style)),
          list,
        ],
      );
    }

    final columns = settings.resolvedBrowseGridColumnCount;

    return SliverGrid(
      delegate: delegate,
      // 0 columns means "auto": size by extent so tablets and desktop windows stay sensible.
      gridDelegate: columns > 0
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
    );
  }

  static Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);
}
