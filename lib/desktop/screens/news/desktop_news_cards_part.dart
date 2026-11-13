part of 'desktop_news_screen.dart';

class _NewsMasonrySliver extends StatelessWidget {
  final List<News> visible;
  final double minColumnWidth;

  const _NewsMasonrySliver({
    required this.visible,
    required this.minColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.pagePadding,
      ),
      // Rebuilt only when the column count changes; between
      // those a resize just re-lays the cards out.
      sliver: DerivedSliverLayoutBuilder<int>(
        derive: (constraints) =>
            (constraints.crossAxisExtent / minColumnWidth).floor().clamp(1, 3),
        builder: (context, columns) {
          const gap = 16.0;
          return SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = c; i < visible.length; i += columns)
                          Padding(
                            padding: const EdgeInsets.only(bottom: gap),
                            child: _NewsCard(
                              key: ValueKey('news_${visible[i].id}'),
                              news: visible[i],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatDate(String date) {
  if (date.isEmpty) return '';
  try {
    return DateFormat('MMM d, yyyy').format(DateTime.parse(date));
  } on FormatException {
    return date;
  }
}

class _NewsCard extends StatelessWidget {
  final News news;

  const _NewsCard({super.key, required this.news});

  static const double _coverWidth = 72;
  static const double _coverSpacing = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return DesktopHoverSurface(
      onTap: () => launchUrl(Uri.parse(news.url)),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Row(
                  children: [
                    if (news.source.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.accent.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.pillRadius,
                            ),
                          ),
                          child: Text(
                            news.source.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel(
                              color: context.colors.accent,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    if (news.source.isNotEmpty) const SizedBox(width: 10),
                    Text(
                      _formatDate(news.publishedAt),
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                news.title,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (news.author.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.translate('by_author')} ${news.author}',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              if (news.series.isNotEmpty) ...[
                const SizedBox(height: 16),
                DerivedLayoutBuilder<int>(
                  derive: (constraints) {
                    final total = news.series.length;
                    // How many cover-sized slots actually fit on one row.
                    final perRow =
                        ((constraints.maxWidth + _coverSpacing) /
                                (_coverWidth + _coverSpacing))
                            .floor()
                            .clamp(1, total);
                    // If everything fits, no overflow tile is needed; otherwise
                    // the last slot on the row becomes the "+x" tile instead of
                    // wrapping it alone onto a second row.
                    return total <= perRow ? total : perRow - 1;
                  },
                  builder: (context, showCount) {
                    final total = news.series.length;
                    final extra = total - showCount;
                    return Wrap(
                      spacing: _coverSpacing,
                      runSpacing: _coverSpacing,
                      children: [
                        for (final s in news.series.take(showCount))
                          DesktopCoverCard(
                            series: s,
                            width: _coverWidth,
                            showTitle: false,
                            heroTag: 'news_${news.id}',
                          ),
                        if (extra > 0)
                          Container(
                            width: _coverWidth,
                            height: 108,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.colors.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$extra',
                              style: AppTypography.display(
                                color: context.colors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
