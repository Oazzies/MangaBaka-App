part of 'series_hover_preview.dart';

class _SeriesPreviewCard extends StatelessWidget {
  final GlobalKey cardKey;
  final Series series;

  const _SeriesPreviewCard({required this.cardKey, required this.series});

  String _cleanSynopsis(String text) {
    if (text.isEmpty) return '';
    return MarkdownUtils.toPlainText(
      text,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildMetaBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.monoLabel(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ).copyWith(decoration: TextDecoration.none),
      ),
    );
  }

  String _capitalizeGenre(String text) {
    if (text.isEmpty) return text;
    final formatted = text.replaceAll('_', ' ');
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final displayTitle = series.getDisplayTitle(settings.defaultTitleLanguage);
    final ratingNum = double.tryParse(series.rating) ?? 0.0;
    final ratingDisplay = ratingNum > 10
        ? (ratingNum / 10).toStringAsFixed(1)
        : (ratingNum > 0 ? ratingNum.toStringAsFixed(1) : '');

    final chapters = series.totalChapters;
    final volumes = series.finalVolume;
    final year = series.year;

    final subMetaParts = <String>[];
    if (volumes.isNotEmpty && volumes != '0') {
      subMetaParts.add('Vol. $volumes');
    }
    if (chapters.isNotEmpty && chapters != '0') {
      subMetaParts.add('Ch. $chapters');
    }
    if (year.isNotEmpty) {
      subMetaParts.add(year);
    }

    final synopsis = _cleanSynopsis(series.description);
    final genres = series.genres;

    return Column(
      key: cardKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Blown-up Cover with realistic drop shadow
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowAt(0.65),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: context.colors.shadowAt(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: series.coverUrl.isNotEmpty
                  ? WidgetUtils.networkImage(
                      url: series.coverUrl,
                      blurred: WidgetUtils.isRatingBlurred(
                        series.contentRating,
                      ),
                      fit: BoxFit.cover,
                      memCacheWidth:
                          WidgetUtils.shownDecodeWidth(series.coverUrl) ?? 460,
                      fadeIn: Duration.zero,
                    )
                  : Container(
                      color: context.colors.surfaceRaised,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: context.colors.textMuted,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Info Card beneath the cover - solid background (no semi-transparency)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowAt(0.5),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ).copyWith(decoration: TextDecoration.none),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  if (series.type.isNotEmpty) ...[
                    _buildMetaBadge(
                      series.type.toUpperCase(),
                      context.colors.forSeriesType(series.type),
                    ),
                    const SizedBox(width: 7),
                  ],
                  if (series.status.isNotEmpty) ...[
                    _buildMetaBadge(
                      series.status.toUpperCase(),
                      context.colors.forSeriesStatus(series.status),
                    ),
                  ],
                  if (ratingDisplay.isNotEmpty) ...[
                    const Spacer(),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: context.colors.star,
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      ratingDisplay,
                      style: AppTypography.sans(
                        color: context.colors.star,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ).copyWith(decoration: TextDecoration.none),
                    ),
                  ],
                ],
              ),
              if (subMetaParts.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    for (int i = 0; i < subMetaParts.length; i++) ...[
                      if (i > 0) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: context.colors.textMuted.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Text(
                        subMetaParts[i],
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ).copyWith(decoration: TextDecoration.none),
                      ),
                    ],
                  ],
                ),
              ],
              if (genres.isNotEmpty) ...[
                const SizedBox(height: 7),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final g in genres.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.colors.border.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _capitalizeGenre(g),
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ).copyWith(decoration: TextDecoration.none),
                        ),
                      ),
                  ],
                ),
              ],
              if (synopsis.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  synopsis,
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ).copyWith(decoration: TextDecoration.none),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
