part of 'series_hover_preview.dart';

class _SeriesPreviewOverlay extends StatefulWidget {
  final Series? initialSeries;
  final String seriesId;

  const _SeriesPreviewOverlay({
    required this.initialSeries,
    required this.seriesId,
  });

  @override
  State<_SeriesPreviewOverlay> createState() => _SeriesPreviewOverlayState();
}

class _SeriesPreviewOverlayState extends State<_SeriesPreviewOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  double _measuredHeight = 560.0;

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Series? _series;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(curved);
    _animController.forward();

    _series = widget.initialSeries;
    _loadFullSeriesIfNeeded();
  }

  Future<void> _loadFullSeriesIfNeeded() async {
    final seriesService = getIt<SeriesService>();
    final cached = seriesService.cache[widget.seriesId];
    if (cached != null) {
      if (mounted && (_series == null || _series!.description.isEmpty)) {
        setState(() => _series = cached);
      }
      return;
    }

    if (_series == null ||
        _series!.description.isEmpty ||
        _series!.genres.isEmpty) {
      try {
        final fetched = await seriesService.fetchSeries(widget.seriesId);
        if (mounted) {
          setState(() => _series = fetched);
        }
      } catch (e, st) {
        // Fall back to initial series if fetch fails
        LoggingService.logger.fine(
          'Hover preview prefetch failed for series ${widget.seriesId}',
          e,
          st,
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = _series ?? widget.initialSeries;
    if (series == null) return const SizedBox.shrink();

    const double previewWidth = 230.0;
    const double cursorOffset = 18.0;

    // Dynamically measure the exact height of the preview card after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ro = _cardKey.currentContext?.findRenderObject() as RenderBox?;
      if (ro != null && ro.hasSize && ro.size.height > 50) {
        if ((ro.size.height - _measuredHeight).abs() > 4) {
          setState(() {
            _measuredHeight = ro.size.height;
          });
        }
      }
    });

    return IgnorePointer(
      ignoring: true,
      child: ValueListenableBuilder<Offset>(
        valueListenable: SeriesHoverPreviewController.instance.mousePosition,
        builder: (context, mousePos, child) {
          final screenSize = MediaQuery.sizeOf(context);
          final double x = mousePos.dx;
          final double y = mousePos.dy;

          // Flip to left of cursor if nearing the right screen edge
          final bool flipLeft =
              (x + cursorOffset + previewWidth) > (screenSize.width - 20.0);
          final double left = flipLeft
              ? (x - cursorOffset - previewWidth).clamp(
                  12.0,
                  screenSize.width - previewWidth - 12.0,
                )
              : (x + cursorOffset).clamp(
                  12.0,
                  screenSize.width - previewWidth - 12.0,
                );

          // Ensure preview never spawns or overflows offscreen at the bottom or top
          final double effectiveHeight = _measuredHeight;
          const double bottomMargin = 16.0;
          final double maxTop =
              screenSize.height - effectiveHeight - bottomMargin;
          final double desiredTop = y - 100.0;
          final double top = desiredTop.clamp(
            12.0,
            maxTop < 12.0 ? 12.0 : maxTop,
          );

          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: previewWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (screenSize.height - 24.0).clamp(
                      200.0,
                      double.infinity,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: DefaultTextStyle(
                      style: AppTypography.sans(
                        color: context.colors.text,
                      ).copyWith(decoration: TextDecoration.none),
                      child: FadeTransition(
                        opacity: _fade,
                        child: ScaleTransition(
                          scale: _scale,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: _SeriesPreviewCard(
                              cardKey: _cardKey,
                              series: series,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
