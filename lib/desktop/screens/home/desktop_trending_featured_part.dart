part of 'desktop_trending_board.dart';

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
            Opacity(
              opacity: 0.35,
              child: WidgetUtils.networkImage(
                url: series.coverUrl,
                memCacheWidth: 24,
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
              child: CustomMultiChildLayout(
                delegate: _FeaturedLayout(),
                children: [
                  LayoutId(
                    id: _FeaturedSlot.cover,
                    child: AspectRatio(
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
                  ),
                  LayoutId(
                    id: _FeaturedSlot.info,
                    child: ClipRect(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            SizedBox(
                              height: 30,
                              child: ClipRect(
                                child: Wrap(
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
                              ),
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

enum _FeaturedSlot { cover, info }

/// Cover on the left at a clamped share of the width, the details filling
/// the rest.
class _FeaturedLayout extends MultiChildLayoutDelegate {
  static const double _gap = 24;

  @override
  void performLayout(Size size) {
    final coverWidth = (size.width * 0.36).clamp(90.0, 200.0);
    layoutChild(
      _FeaturedSlot.cover,
      BoxConstraints(maxWidth: coverWidth, maxHeight: size.height),
    );
    positionChild(_FeaturedSlot.cover, Offset.zero);
    final infoLeft = coverWidth + _gap;
    layoutChild(
      _FeaturedSlot.info,
      BoxConstraints.tight(
        Size(math.max(0, size.width - infoLeft), size.height),
      ),
    );
    positionChild(_FeaturedSlot.info, Offset(infoLeft, 0));
  }

  @override
  bool shouldRelayout(_FeaturedLayout oldDelegate) => false;
}
