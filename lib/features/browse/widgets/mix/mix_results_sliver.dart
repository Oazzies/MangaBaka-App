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
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';

/// The recommendations themselves, plus the four states that stand in for
/// them: no seeds yet, generating, failed, and generated-but-empty.
///
/// Listens to [SettingsManager] on its own rather than through the screen's
/// merged listenable. List style and grid density are only read here, so a
/// settings change now rebuilds this sliver instead of the seed picker, the
/// options card and the DNA bars along with it.
class MixResultsSliver extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;
  final ValueChanged<Series> onSeriesTap;

  const MixResultsSliver({
    super.key,
    required this.controller,
    required this.l10n,
    required this.onSeriesTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSeeds) {
      return _fill(MixEmptyState(l10n: l10n));
    }
    if (controller.isLoading) {
      return _fill(MixLoadingState(l10n: l10n));
    }
    if (controller.error != null) {
      return _fill(MixErrorState(l10n: l10n, onRetry: controller.refresh));
    }
    if (controller.results.isEmpty) {
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
        child: EntryListItem(key: ValueKey('mix_${series.id}'), series: series),
      );
    }, childCount: controller.results.length);

    // The list styles are row layouts, not cells — forcing them through a grid
    // delegate squeezes them into cover-shaped boxes.
    if (!style.isGrid) {
      final list = SliverList(delegate: delegate);
      if (!DesktopLayout.isActive(context)) return list;
      // On desktop the list styles are tables, so they get column labels.
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
      // A column count of 0 means "auto": fall back to sizing by extent so the
      // grid stays sensible on a tablet or a desktop window.
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
