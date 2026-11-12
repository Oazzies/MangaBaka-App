import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/series/models/related_series.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

class SeriesRelatedTab extends StatelessWidget {
  final List<RelatedSeries>? related;
  final LocalizationService l10n;
  final double horizontalPadding;

  final String? currentSeriesId;
  final String? heroTagPrefix;

  const SeriesRelatedTab({
    super.key,
    this.related,
    required this.l10n,
    this.horizontalPadding = 16.0,
    this.currentSeriesId,
    this.heroTagPrefix,
  });

  static const List<String> _relationOrder = [
    'prequel',
    'sequel',
    'main_story',
    'parent_story',
    'parent',
    'side_story',
    'spin_off',
    'adaptation',
    'alternative',
    'alternative_version',
    'alternative_setting',
    'full_story',
    'summary',
    'compilation',
    'contains',
    'character',
    'source',
    'other',
  ];

  static String _normalizeRelationType(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

  /// Resolves a localized label for [relationType], falling back to a
  /// title-cased form when the API introduces an unmapped relation type.
  static String formatRelationType(
    LocalizationService l10n,
    String relationType,
  ) {
    final normalized = _normalizeRelationType(relationType);
    if (normalized.isEmpty) {
      return l10n.translate('tab_related');
    }
    final key = 'relation_$normalized';
    final translated = l10n.translate(key);
    if (translated != key) return translated;

    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<MapEntry<String, List<Series>>> _groupRelated(
    List<RelatedSeries> items,
  ) {
    final grouped = <String, Map<String, Series>>{};
    for (final item in items) {
      if (item.series.id == currentSeriesId) continue;
      final type = _normalizeRelationType(item.relationType);
      grouped.putIfAbsent(type, () => <String, Series>{})[item.series.id] =
          item.series;
    }

    final entries = grouped.entries
        .map((e) => MapEntry(e.key, e.value.values.toList()))
        .where((e) => e.value.isNotEmpty)
        .toList();

    entries.sort((a, b) {
      final ia = _relationOrder.indexOf(a.key);
      final ib = _relationOrder.indexOf(b.key);
      if (ia != -1 && ib != -1) return ia.compareTo(ib);
      if (ia != -1) return -1;
      if (ib != -1) return 1;
      return 0;
    });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (related == null) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32.0), child: MbSpinner()),
      );
    }

    final groups = _groupRelated(related!);
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.translate('no_related_series')),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          final style = settings.resolvedBrowseListStyle;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const SizedBox(height: 24),
                _buildSection(
                  context,
                  settings: settings,
                  style: style,
                  relationType: groups[i].key,
                  series: groups[i].value,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required SettingsManager settings,
    required AppListStyle style,
    required String relationType,
    required List<Series> series,
  }) {
    final sectionPrefix =
        '${heroTagPrefix ?? 'related'}_${relationType.isEmpty ? 'other' : relationType}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesSectionHeader(title: formatRelationType(l10n, relationType)),
        LayoutBuilder(
          builder: (context, constraints) {
            if (style.isGrid) {
              return _buildGrid(
                context,
                settings,
                style,
                series,
                constraints.maxWidth,
                sectionPrefix,
              );
            }
            return _buildList(context, series, sectionPrefix);
          },
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    SeriesService seriesService,
    Series s,
    String sectionPrefix,
  ) {
    return MouseRegion(
      onEnter: (_) => seriesService.fetchSeries(s.id),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            AppTransitions.slideUp(
              SeriesDetailScreen(series: s, heroTagPrefix: sectionPrefix),
            ),
          );
        },
        child: EntryListItem(series: s, heroTagPrefix: sectionPrefix),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Series> series,
    String sectionPrefix,
  ) {
    final seriesService = getIt<SeriesService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in series)
          _buildItem(context, seriesService, s, sectionPrefix),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    SettingsManager settings,
    AppListStyle style,
    List<Series> series,
    double maxWidth,
    String sectionPrefix,
  ) {
    final seriesService = getIt<SeriesService>();
    final columnCount = settings.resolvedBrowseGridColumnCount;
    const spacing = 10.0;
    final cols = columnCount > 0
        ? columnCount
        : (maxWidth / 160).floor().clamp(2, 6);
    final itemWidth = (maxWidth - spacing * (cols - 1)) / cols;
    // Compact grid needs room for the title rows under the cover, so take the
    // ratio from the style rather than assuming a bare cover.
    final itemHeight = itemWidth / style.childAspectRatio;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: series
          .map(
            (s) => SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _buildItem(context, seriesService, s, sectionPrefix),
            ),
          )
          .toList(),
    );
  }
}
