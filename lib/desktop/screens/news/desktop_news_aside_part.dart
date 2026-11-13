part of 'desktop_news_screen.dart';

class _NewsAsidePanel extends StatelessWidget {
  final List<(Series, int)> mentioned;

  const _NewsAsidePanel({required this.mentioned});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    // Laid out like the Upcoming Releases rail: a header that starts below the
    // window controls, a hairline, then the scrolling list.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 28, 16),
          child: Text(
            l10n.translate('in_the_news').toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 18,
            ),
          ),
        ),
        Divider(height: 1, color: context.colors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (mentioned.isEmpty)
                Text(
                  l10n.translate('no_results'),
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              for (final (series, count) in mentioned)
                _MentionRow(series: series, count: count),
            ],
          ),
        ),
      ],
    );
  }
}

class _MentionRow extends StatelessWidget {
  final Series series;
  final int count;

  const _MentionRow({required this.series, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SeriesHoverPreview(
        series: series,
        child: DesktopHoverSurface(
          onTap: () => openSeriesDetail(context, series, heroTag: 'news_aside'),
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: WidgetUtils.networkImage(
                  url: series.coverUrl,
                  blurred: WidgetUtils.isRatingBlurred(series.contentRating),
                  width: 40,
                  height: 60,
                  memCacheWidth: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.getDisplayTitle(
                        SettingsManager().defaultTitleLanguage,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n
                          .translate('mention_count')
                          .replaceAll('{count}', '$count'),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
