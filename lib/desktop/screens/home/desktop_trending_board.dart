import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_rating_stars.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Trending as a chart: the #1 series featured large, the next places ranked
/// beside it, with the type and time-window controls in the header.
class DesktopTrendingBoard extends StatelessWidget {
  final List<Series> series;
  final bool loading;
  final String? selectedType;
  final int window;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback onViewAll;

  /// Ranked places shown beside the featured one.
  static const int _rankedCount = 8;

  const DesktopTrendingBoard({
    super.key,
    required this.series,
    required this.loading,
    required this.selectedType,
    required this.window,
    required this.onTypeChanged,
    required this.onWindowChanged,
    required this.onViewAll,
  });

  static const List<(String?, String)> _types = [
    (null, 'any'),
    ('manga', 'type_manga'),
    ('manhwa', 'type_manhwa'),
    ('manhua', 'type_manhua'),
    ('novel', 'type_novel'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionTitle(
          title: l10n.translate('trending'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DesktopSegmented<String?>(
                value: selectedType,
                segments: [
                  for (final (value, key) in _types)
                    (value, l10n.translate(key), null),
                ],
                onChanged: onTypeChanged,
              ),
              const SizedBox(width: 10),
              DesktopSegmented<int>(
                value: window,
                segments: const [(7, '7d', null), (30, '30d', null)],
                onChanged: onWindowChanged,
              ),
              const SizedBox(width: 10),
              DesktopPillButton(
                label: l10n.translate('view_all'),
                onPressed: onViewAll,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 420,
          child: loading
              ? const _BoardSkeleton()
              : series.isEmpty
              ? DesktopEmptyState(
                  icon: Icons.trending_up_rounded,
                  message: l10n.translate('no_results'),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _FeaturedCard(series: series.first),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: _rankedGrid()),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _rankedGrid() {
    final ranked = series.skip(1).take(_rankedCount).toList();
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      final row = Expanded(
        child: _RankedRow(series: ranked[i], rank: i + 2),
      );
      (i < _rankedCount / 2 ? left : right).add(row);
    }
    // Pad short columns so rows keep the same height either side.
    while (left.length < _rankedCount / 2) {
      left.add(const Spacer());
    }
    while (right.length < _rankedCount / 2) {
      right.add(const Spacer());
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Series series;

  const _FeaturedCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = series.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );
    final rating = double.tryParse(series.rating) ?? 0;
    final meta = [
      if (series.type.isNotEmpty) l10n.translate('type_${series.type}'),
      if (series.year.isNotEmpty) series.year,
      if (series.status.isNotEmpty) l10n.translate('status_${series.status}'),
    ].join('  ·  ');
    final metadata = getIt<MetadataService>();

    return DesktopHoverSurface(
      onTap: () => openSeriesDetail(context, series, heroTag: 'trending_1'),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The cover, blurred, as a backdrop — the colour of the book
            // carries into the card without competing with the text.
            Opacity(
              opacity: 0.35,
              child: WidgetUtils.networkImage(
                url: series.coverUrl,
                blurred: true,
                memCacheWidth: 200,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.colors.background.withValues(alpha: 0.3),
                    context.colors.background.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WidgetUtils.networkImage(
                        url: series.coverUrl,
                        blurred: WidgetUtils.isRatingBlurred(
                          series.contentRating,
                        ),
                        memCacheWidth: 500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.accent,
                            borderRadius: BorderRadius.circular(
                              AppConstants.pillRadius,
                            ),
                          ),
                          child: Text(
                            '#1 ${l10n.translate('trending')}'.toUpperCase(),
                            style: AppTypography.display(
                              color: context.colors.onAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title.toUpperCase(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            color: context.colors.text,
                            fontSize: 28,
                            height: 1.1,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            meta,
                            style: AppTypography.sans(
                              color: context.colors.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (rating > 0) ...[
                          const SizedBox(height: 10),
                          MbRatingStars(
                            rating: rating,
                            outOf: 100,
                            fontSize: 14,
                          ),
                        ],
                        if (series.genres.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final g in series.genres.take(4))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.surfaceRaised
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.pillRadius,
                                    ),
                                  ),
                                  child: Text(
                                    metadata.getGenreLabel(g),
                                    style: AppTypography.sans(
                                      color: context.colors.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (series.description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Expanded(
                            child: Text(
                              series.description,
                              overflow: TextOverflow.fade,
                              style: AppTypography.sans(
                                color: context.colors.text.withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final Series series;
  final int rank;

  const _RankedRow({required this.series, required this.rank});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = series.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );
    final rating = double.tryParse(series.rating) ?? 0;
    final meta = [
      if (series.type.isNotEmpty) l10n.translate('type_${series.type}'),
      if (series.year.isNotEmpty) series.year,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DesktopHoverSurface(
        onTap: () =>
            openSeriesDetail(context, series, heroTag: 'trending_$rank'),
        idleColor: context.colors.surface,
        hoverColor: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '$rank',
                style: AppTypography.display(
                  color: rank <= 3
                      ? context.colors.accent
                      : context.colors.textMuted,
                  fontSize: 22,
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: WidgetUtils.networkImage(
                  url: series.coverUrl,
                  blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                  memCacheWidth: 120,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(width: 10),
              MbRatingStars(rating: rating, outOf: 100, fontSize: 11),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block() => Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Shimmer.fromColors(
      baseColor: context.colors.surfaceRaised,
      highlightColor: context.colors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: block()),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Expanded(child: block()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
