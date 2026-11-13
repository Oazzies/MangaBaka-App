import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';

part 'series_hover_preview_overlay_part.dart';
part 'series_hover_preview_card_part.dart';

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
