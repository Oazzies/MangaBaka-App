import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_metadata_panels.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_stats_charts.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_stats_widgets.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

class PublisherStatsView extends StatelessWidget {
  final PublisherStats stats;
  final Publisher publisher;
  final LocalizationService l10n;
  final OpenPublisherCallback onOpenPublisher;

  const PublisherStatsView({
    super.key,
    required this.stats,
    required this.publisher,
    required this.l10n,
    required this.onOpenPublisher,
  });

  void _browse(
    BuildContext context, {
    String? genre,
    String? tag,
    required String refine,
  }) {
    Navigator.of(context).push(
      AppTransitions.slideRight(
        BrowseResultsScreen(
          sortType: '${publisher.name} · $refine',
          sortBy: 'popularity_asc',
          publisher: publisher.name,
          publisherId: publisher.id,
          genre: genre,
          tag: tag,
          refineLabel: refine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, _) => _build(
        context,
        SettingsManager().publisherStatsStyle == PublisherStatsStyle.charts,
      ),
    );
  }

  Widget _build(BuildContext context, bool charts) {
    final colors = context.colors;
    final tiles = <(String, String)>[
      (l10n.translate('publisher_series'), formatCount(stats.seriesCount)),
      if (stats.averageScore != null)
        (
          l10n.translate('publisher_stat_avg_score'),
          (stats.averageScore! / 10).toStringAsFixed(1),
        ),
      if (stats.firstYear != null && stats.lastYear != null)
        (
          l10n.translate('publisher_stat_years'),
          stats.firstYear == stats.lastYear
              ? '${stats.firstYear}'
              : '${stats.firstYear}–${stats.lastYear}',
        ),
      if (stats.hasAnime > 0)
        (l10n.translate('publisher_stat_anime'), formatCount(stats.hasAnime)),
    ];

    List<ChartEntry> entries(
      List<StatBucket> b, {
      String Function(String)? label,
      Color Function(String)? color,
    }) => [
      for (final e in b)
        ChartEntry(
          (label ?? capitalizePublisherKey)(e.key),
          e.count,
          color: color?.call(e.key),
        ),
    ];

    Color ratingColor(String k) => switch (k) {
      'safe' => colors.success,
      'suggestive' => colors.warning,
      'erotica' => colors.error.withValues(alpha: 0.75),
      'pornographic' => colors.error,
      _ => colors.textMuted,
    };

    Widget section(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [PublisherSubLabel(label), const SizedBox(height: 8), child],
      ),
    );

    Widget bars(List<ChartEntry> e) =>
        PublisherStatBarList(entries: [for (final x in e) (x.label, x.count)]);

    final decades = entries(stats.decades, label: (k) => '${k}s');
    final media = entries(stats.mediaTypes);
    final status = entries(stats.statuses, color: colors.forSeriesStatus);
    final ratings = entries(stats.contentRatings, color: ratingColor);

    return PublisherPanel(
      label: l10n.translate('publisher_stats'),
      trailing: PublisherStatsStyleToggle(charts: charts),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final (label, value) in tiles)
                PublisherStatTile(label: label, value: value),
            ],
          ),
          if (decades.length > 1)
            section(
              l10n.translate('publisher_by_decade'),
              charts ? ColumnChart(entries: decades) : bars(decades),
            ),
          if (media.length > 1)
            section(
              l10n.translate('publisher_media_types'),
              charts ? BarChartRows(entries: media) : bars(media),
            ),
          if (status.length > 1)
            section(
              l10n.translate('status'),
              charts ? StackedBarChart(entries: status) : bars(status),
            ),
          if (ratings.length > 1)
            section(
              l10n.translate('content_rating'),
              charts ? StackedBarChart(entries: ratings) : bars(ratings),
            ),
          if (stats.knownFor.isNotEmpty)
            _tagBlock(
              context,
              l10n.translate('publisher_known_for'),
              stats.knownFor,
              byGenre: false,
              charts: charts,
            ),
          if (stats.genres.isNotEmpty)
            _tagBlock(
              context,
              l10n.translate('publisher_genres'),
              stats.genres,
              byGenre: true,
              charts: charts,
            ),
          if (stats.audience.isNotEmpty)
            _tagBlock(
              context,
              l10n.translate('publisher_audience'),
              stats.audience,
              byGenre: false,
              charts: charts,
            ),
          if (stats.sharesWith.isNotEmpty)
            section(
              l10n.translate('publisher_shares_with'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in stats.sharesWith.take(10))
                    MbPill(
                      label: p.name,
                      icon: Icons.business_rounded,
                      trailingText: formatCount(p.sharedCount),
                      onTap: p.id.isEmpty
                          ? null
                          : () => onOpenPublisher(
                              context,
                              id: p.id,
                              name: p.name,
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tagBlock(
    BuildContext context,
    String label,
    List<StatTag> tags, {
    required bool byGenre,
    required bool charts,
  }) {
    void open(StatTag t) => byGenre
        ? _browse(context, genre: t.name, refine: t.name)
        : _browse(context, tag: t.id, refine: t.name);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PublisherSubLabel(label),
          const SizedBox(height: 8),
          if (charts)
            Column(
              children: [
                for (final t in tags.take(8))
                  ShareBarRow(
                    label: t.name,
                    share: t.share,
                    catalogShare: t.catalogShare,
                    count: t.count,
                    onTap: () => open(t),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.translate('publisher_share_legend'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags.take(10))
                  MbPill(
                    label: t.name,
                    trailingText: formatCount(t.count),
                    onTap: () => open(t),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
