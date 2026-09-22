import 'package:mangabaka_app/features/series/widgets/unblur_warning.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/full_screen_image_screen.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SeriesHeroCover extends StatefulWidget {
  final Series series;
  final double height;
  final double width;
  final String? heroTagPrefix;

  const SeriesHeroCover({
    super.key,
    required this.series,
    required this.height,
    required this.width,
    this.heroTagPrefix,
  });

  @override
  State<SeriesHeroCover> createState() => _SeriesHeroCoverState();
}

class _SeriesHeroCoverState extends State<SeriesHeroCover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTagPrefix != null
          ? '${widget.heroTagPrefix}_${widget.series.id}'
          : 'series_cover_${widget.series.id}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () async {
            final imageUrl = widget.series.rawCoverUrl.isNotEmpty
                ? widget.series.rawCoverUrl
                : widget.series.coverUrl;
            if (imageUrl.isNotEmpty) {
              // Fullscreen shows the cover clear, so a blurred one asks first.
              if (WidgetUtils.isRatingBlurred(widget.series.contentRating) &&
                  !await confirmUnblur(context)) {
                return;
              }
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageScreen(
                    imageUrls: [imageUrl],
                    heroTag: widget.heroTagPrefix != null
                        ? '${widget.heroTagPrefix}_${widget.series.id}'
                        : 'series_cover_${widget.series.id}',
                  ),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _hovered
                  ? Border.all(
                      color: context.colors.accent.withValues(alpha: 0.6),
                      width: 2,
                    )
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowAt(_hovered ? 0.4 : 0.6),
                  blurRadius: _hovered ? 28 : 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListenableBuilder(
                listenable: SettingsManager(),
                builder: (context, _) {
                  final isBlurred = SettingsManager().blurredContentRatings
                      .contains(widget.series.contentRating.toLowerCase());
                  return WidgetUtils.networkImage(
                    url: widget.series.coverUrl,
                    height: widget.height,
                    width: widget.width,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    blurred: isBlurred,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
