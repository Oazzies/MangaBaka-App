import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';

/// Central controller managing the series hover preview overlay.
/// Tracks cursor coordinates so the preview smoothly follows the mouse.
class SeriesHoverPreviewController {
  static final SeriesHoverPreviewController instance =
      SeriesHoverPreviewController._();
  SeriesHoverPreviewController._();

  OverlayEntry? _entry;
  Timer? _dwellTimer;
  String? _activeSeriesId;

  /// Global pointer position updated as the cursor moves over a previewable element.
  final ValueNotifier<Offset> mousePosition = ValueNotifier<Offset>(
    Offset.zero,
  );

  void onPointerMove(Offset globalPos) {
    mousePosition.value = globalPos;
  }

  /// Request to show a preview following cursor coordinates near-instantly.
  void show({
    required BuildContext context,
    Series? series,
    String? seriesId,
    required Offset initialPos,
    Duration delay = const Duration(milliseconds: 30),
  }) {
    final targetId = series?.id ?? seriesId;
    if (targetId == null) return;

    mousePosition.value = initialPos;

    if (_activeSeriesId == targetId && _entry != null) {
      return;
    }

    _dwellTimer?.cancel();
    _dwellTimer = Timer(delay, () {
      if (!context.mounted) return;
      _display(context: context, series: series, seriesId: targetId);
    });
  }

  /// Dismiss the active preview overlay immediately.
  void hide() {
    _dwellTimer?.cancel();
    _dwellTimer = null;
    _entry?.remove();
    _entry = null;
    _activeSeriesId = null;
  }

  void _display({
    required BuildContext context,
    Series? series,
    required String seriesId,
  }) {
    _entry?.remove();
    _entry = null;
    _activeSeriesId = seriesId;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) =>
          _SeriesPreviewOverlay(initialSeries: series, seriesId: seriesId),
    );

    overlay.insert(_entry!);
  }
}

/// A wrapper widget that displays a hover preview following the cursor.
class SeriesHoverPreview extends StatefulWidget {
  final Widget child;
  final Series? series;
  final String? seriesId;
  final bool enabled;

  const SeriesHoverPreview({
    super.key,
    required this.child,
    this.series,
    this.seriesId,
    this.enabled = true,
  });

  @override
  State<SeriesHoverPreview> createState() => _SeriesHoverPreviewState();
}

class _SeriesHoverPreviewState extends State<SeriesHoverPreview> {
  @override
  void dispose() {
    final id = widget.series?.id ?? widget.seriesId;
    if (id != null &&
        SeriesHoverPreviewController.instance._activeSeriesId == id) {
      SeriesHoverPreviewController.instance.hide();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !DesktopLayout.isDesktopPlatform) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => SeriesHoverPreviewController.instance.hide(),
      child: MouseRegion(
        onEnter: (event) {
          SeriesHoverPreviewController.instance.show(
            context: context,
            series: widget.series,
            seriesId: widget.seriesId,
            initialPos: event.position,
          );
        },
        onHover: (event) {
          SeriesHoverPreviewController.instance.onPointerMove(event.position);
        },
        onExit: (_) {
          SeriesHoverPreviewController.instance.hide();
        },
        child: widget.child,
      ),
    );
  }
}

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
      } catch (_) {
        // Fall back to initial series if fetch fails
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _cleanSynopsis(String text) {
    if (text.isEmpty) return '';
    return MarkdownUtils.toPlainText(
      text,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('ongoing')) {
      return context.colors.success;
    } else if (s.contains('completed')) {
      return context.colors.info;
    } else if (s.contains('hiatus')) {
      return context.colors.warning;
    } else if (s.contains('cancelled') || s.contains('canceled')) {
      return context.colors.error;
    } else {
      return context.colors.textMuted;
    }
  }

  String _capitalizeGenre(String text) {
    if (text.isEmpty) return text;
    final formatted = text.replaceAll('_', ' ');
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final series = _series ?? widget.initialSeries;
    if (series == null) return const SizedBox.shrink();

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
                            child: Column(
                              key: _cardKey,
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
                                      color: context.colors.border.withValues(
                                        alpha: 0.5,
                                      ),
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
                                              blurred:
                                                  WidgetUtils.isRatingBlurred(
                                                    series.contentRating,
                                                  ),
                                              fit: BoxFit.cover,
                                              memCacheWidth: 460,
                                            )
                                          : Container(
                                              color:
                                                  context.colors.surfaceRaised,
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
                                    border: Border.all(
                                      color: context.colors.border,
                                      width: 1,
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        displayTitle,
                                        style:
                                            AppTypography.display(
                                              color: context.colors.text,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                            ).copyWith(
                                              decoration: TextDecoration.none,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 7),
                                      // Badges Row
                                      Row(
                                        children: [
                                          if (series.type.isNotEmpty) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context.colors.accent
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                series.type.toUpperCase(),
                                                style:
                                                    AppTypography.monoLabel(
                                                      color:
                                                          context.colors.accent,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ).copyWith(
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                          ],
                                          if (series.status.isNotEmpty) ...[
                                            Builder(
                                              builder: (_) {
                                                final statusColor =
                                                    _statusColor(series.status);
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    series.status.toUpperCase(),
                                                    style:
                                                        AppTypography.monoLabel(
                                                          color: statusColor,
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ).copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                  ),
                                                );
                                              },
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
                                              style:
                                                  AppTypography.sans(
                                                    color: context.colors.star,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                  ).copyWith(
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      // Chapters / Volumes / Year
                                      if (subMetaParts.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            for (
                                              int i = 0;
                                              i < subMetaParts.length;
                                              i++
                                            ) ...[
                                              if (i > 0) ...[
                                                const SizedBox(width: 7),
                                                Container(
                                                  width: 3,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: context
                                                        .colors
                                                        .textMuted
                                                        .withValues(alpha: 0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 7),
                                              ],
                                              Text(
                                                subMetaParts[i],
                                                style:
                                                    AppTypography.sans(
                                                      color: context
                                                          .colors
                                                          .textMuted,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ).copyWith(
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                      // Genres
                                      if (genres.isNotEmpty) ...[
                                        const SizedBox(height: 7),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            for (final g in genres.take(3))
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context
                                                      .colors
                                                      .surfaceRaised,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: context.colors.border
                                                        .withValues(alpha: 0.5),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  _capitalizeGenre(g),
                                                  style:
                                                      AppTypography.sans(
                                                        color: context
                                                            .colors
                                                            .textMuted,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ).copyWith(
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      // Synopsis
                                      if (synopsis.isNotEmpty) ...[
                                        const SizedBox(height: 7),
                                        Text(
                                          synopsis,
                                          style:
                                              AppTypography.sans(
                                                color: context.colors.textMuted,
                                                fontSize: 11,
                                                height: 1.35,
                                              ).copyWith(
                                                decoration: TextDecoration.none,
                                              ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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
