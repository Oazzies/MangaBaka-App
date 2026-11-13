part of 'desktop_upcoming_rail.dart';

class _UpcomingWorkCard extends StatelessWidget {
  final SeriesWork work;
  final bool inLibrary;
  final String? fallbackCoverUrl;

  const _UpcomingWorkCard({
    required this.work,
    required this.inLibrary,
    this.fallbackCoverUrl,
  });

  void _openSeries(BuildContext context) async {
    if (work.seriesId == null) return;
    SeriesHoverPreviewController.instance.hide();
    final seriesService = getIt<SeriesService>();
    try {
      final series = await seriesService.fetchSeries(work.seriesId.toString());
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).push(AppTransitions.slideRight(SeriesDetailScreen(series: series)));
    } catch (e, st) {
      LoggingService.logger.warning(
        'Opening series ${work.seriesId} failed',
        e,
        st,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          LocalizationService().translate('open_series_failed'),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = work.seriesTitle ?? work.subTitle;
    // The release date is carried by the group header above the card.
    final subtitle = work.sequenceString.isNotEmpty
        ? 'Vol. ${work.sequenceString}'
        : '';

    final card = DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: work.seriesId != null ? () => _openSeries(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 68,
                child: _UpcomingWorkCover(
                  work: work,
                  fallbackCoverUrl: fallbackCoverUrl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (inLibrary) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        LocalizationService()
                            .translate('upcoming_in_library')
                            .toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.accent,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (work.seriesId == null) return card;

    final initialSeries = Series(
      id: work.seriesId.toString(),
      state: '',
      title: title,
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: const [],
      coverUrl: work.imageUrl ?? fallbackCoverUrl ?? '',
      rawCoverUrl: work.imageUrl ?? fallbackCoverUrl ?? '',
      authors: const [],
      artists: const [],
      description: '',
      year: '',
      status: '',
      isLicensed: '',
      hasAnime: '',
      contentRating: '',
      type: '',
      rating: '',
      finalVolume: '',
      totalChapters: '',
      links: const [],
      publishers: const [],
      genres: const [],
      tags: const [],
      lastUpdated: '',
    );

    return SeriesHoverPreview(
      series: initialSeries,
      seriesId: work.seriesId.toString(),
      child: card,
    );
  }
}

class _UpcomingWorkCover extends StatefulWidget {
  final SeriesWork work;
  final String? fallbackCoverUrl;

  const _UpcomingWorkCover({required this.work, this.fallbackCoverUrl});

  @override
  State<_UpcomingWorkCover> createState() => _UpcomingWorkCoverState();
}

class _UpcomingWorkCoverState extends State<_UpcomingWorkCover> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _UpcomingWorkCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.work.id != widget.work.id ||
        oldWidget.work.imageUrl != widget.work.imageUrl ||
        oldWidget.fallbackCoverUrl != widget.fallbackCoverUrl) {
      _resolve();
    }
  }

  void _resolve() {
    if (widget.work.imageUrl != null && widget.work.imageUrl!.isNotEmpty) {
      _resolvedUrl = widget.work.imageUrl;
      return;
    }
    if (widget.fallbackCoverUrl != null &&
        widget.fallbackCoverUrl!.isNotEmpty) {
      _resolvedUrl = widget.fallbackCoverUrl;
      return;
    }
    final sid = widget.work.seriesId;
    if (sid != null) {
      final seriesService = getIt<SeriesService>();
      final cached = seriesService.cache[sid.toString()];
      if (cached != null) {
        final cover = cached.coverUrl;
        if (cover.isNotEmpty) {
          _resolvedUrl = cover;
          return;
        }
      }
      seriesService
          .fetchSeries(sid.toString())
          .then((s) {
            if (mounted) {
              final cover = s.coverUrl;
              if (cover.isNotEmpty) {
                setState(() => _resolvedUrl = cover);
              }
            }
          })
          .catchError((Object e, StackTrace st) {
            LoggingService.logger.fine(
              'Upcoming cover lookup failed for $sid',
              e,
              st,
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) {
      return WidgetUtils.networkImage(
        url: _resolvedUrl!,
        fit: BoxFit.cover,
        memCacheWidth: WidgetUtils.decodeWidth(context, 48),
      );
    }
    return Container(
      color: context.colors.surfaceRaised,
      child: Icon(
        Icons.book_outlined,
        size: 20,
        color: context.colors.textMuted,
      ),
    );
  }
}
