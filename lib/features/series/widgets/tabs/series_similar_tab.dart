import 'package:mangabaka_app/core/widgets/list_style_switch.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/tabs/series_similar_grid.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

class SeriesSimilarTab extends StatelessWidget {
  final List<Series>? similar;
  final List<Series>? readersAlsoLike;
  final LocalizationService l10n;
  final SeriesListDeps deps;
  final double horizontalPadding;
  final String? currentSeriesId;

  const SeriesSimilarTab({
    super.key,
    required this.similar,
    this.readersAlsoLike,
    required this.l10n,
    required this.deps,
    this.horizontalPadding = 16.0,
    this.currentSeriesId,
  });

  List<Series> _dedupe(List<Series> source) {
    final unique = <String, Series>{};
    for (final s in source) {
      if (s.id != currentSeriesId) unique[s.id] = s;
    }
    return unique.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (similar == null) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: MbSpinner()),
      );
    }

    final similarList = _dedupe(similar!);
    final readersList = _dedupe(readersAlsoLike ?? const []);

    if (similarList.isEmpty && readersList.isEmpty) {
      if (readersAlsoLike == null) {
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: MbSpinner()),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(child: Text(l10n.translate('no_similar_series'))),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListStyleSwitchGate(
        nestedInScrollView: true,
        child: ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final settings = SettingsManager();
            final style = settings.similarListStyle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (similarList.isNotEmpty)
                  _section(
                    context,
                    title: l10n.translate('tab_similar'),
                    series: similarList,
                    style: style,
                    // The same series can be in both lists, and a Hero tag must be unique within a route.
                    heroTagPrefix: 'similar',
                    toggle: IconButton(
                      icon: Icon(style.next.icon, color: context.colors.text),
                      onPressed: () => ListStyleSwitch.run(
                        () => settings.setSimilarListStyle(style.next),
                      ),
                    ),
                  ),
                if (readersList.isNotEmpty) ...[
                  if (similarList.isNotEmpty) const SizedBox(height: 32),
                  _section(
                    context,
                    title: l10n.translate('readers_also_like'),
                    series: readersList,
                    style: style,
                    heroTagPrefix: 'readers',
                    toggle: similarList.isEmpty
                        ? IconButton(
                            icon: Icon(
                              style.next.icon,
                              color: context.colors.text,
                            ),
                            onPressed: () => ListStyleSwitch.run(
                              () => settings.setSimilarListStyle(style.next),
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Series> series,
    required AppListStyle style,
    required String heroTagPrefix,
    Widget? toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              ConstrainedBox(
                // Holds the toggle, so its hover highlight stays inside the header.
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SeriesSectionHeader(title: title),
                ),
              ),
              if (toggle != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: WidgetUtils.tooltip(
                      message: l10n.translate('toggle_layout'),
                      child: Material(
                        type: MaterialType.transparency,
                        child: toggle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (style.isGrid)
          SeriesSimilarGrid(
            series: series,
            style: style,
            heroTagPrefix: heroTagPrefix,
            deps: deps,
          )
        else
          _buildList(context, series, style, heroTagPrefix),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Series> series,
    AppListStyle style,
    String heroTagPrefix,
  ) {
    // Not a nested ListView: in the AnimatedSwitcher it can paint before layout ("RenderBox was not laid out").
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in series)
          MouseRegion(
            onEnter: (_) => deps.prefetch(s.id),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  AppTransitions.slideUp(
                    SeriesDetailScreen(series: s, heroTagPrefix: heroTagPrefix),
                  ),
                );
              },
              child: EntryListItem(
                series: s,
                deps: deps,
                heroTagPrefix: heroTagPrefix,
                listStyle: style,
              ),
            ),
          ),
      ],
    );
  }
}
