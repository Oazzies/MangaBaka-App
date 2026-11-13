part of 'desktop_trending_board.dart';

class _RankedGridStretched extends StatelessWidget {
  final List<Series> series;
  final int rankedCount;

  const _RankedGridStretched({required this.series, required this.rankedCount});

  @override
  Widget build(BuildContext context) {
    final ranked = series.skip(1).take(rankedCount).toList();
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < ranked.length; i++) {
      final row = Expanded(
        child: _RankedRow(series: ranked[i], rank: i + 2),
      );
      (i < rankedCount / 2 ? left : right).add(row);
    }
    while (left.length < rankedCount / 2) {
      left.add(const Spacer());
    }
    while (right.length < rankedCount / 2) {
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

class _RankedRow extends StatelessWidget {
  final Series series;
  final int rank;

  const _RankedRow({required this.series, required this.rank});

  static const double _coverWidth = 46;

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
            SizedBox(
              width: _coverWidth,
              height: _coverWidth * 1.5,
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
  final bool stacked;
  final double grow;

  const _BoardSkeleton({required this.stacked, required this.grow});

  @override
  Widget build(BuildContext context) {
    Widget block() => Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    if (stacked) {
      return Shimmer.fromColors(
        baseColor: context.colors.surfaceRaised,
        highlightColor: context.colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: DesktopTrendingBoard._stackedCardHeight * grow,
              child: block(),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SizedBox(height: 69, child: block()),
            ],
          ],
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: context.colors.surfaceRaised,
      highlightColor: context.colors.surface,
      child: SizedBox(
        height: DesktopTrendingBoard._cardHeight * grow,
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
      ),
    );
  }
}
