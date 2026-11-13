import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/models/series_cover.dart';
import 'package:mangabaka_app/features/series/screens/full_screen_image_screen.dart';
import 'package:mangabaka_app/features/series/widgets/unblur_warning.dart';

/// A cover grid item that shows an accent border on hover and opens
/// [FullScreenImageScreen] on tap.
class HoverableCoverItem extends StatefulWidget {
  final SeriesCover cover;
  final List<SeriesCover> allCovers;
  final String? url;
  final String title;
  final String? contentRating;
  final List<String> allTitles;
  final List<String?> allNotes;

  const HoverableCoverItem({
    super.key,
    required this.cover,
    required this.allCovers,
    required this.url,
    required this.title,
    this.contentRating,
    required this.allTitles,
    required this.allNotes,
  });

  @override
  State<HoverableCoverItem> createState() => _HoverableCoverItemState();
}

class _HoverableCoverItemState extends State<HoverableCoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.url != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          if (widget.url != null) {
            final rating = widget.contentRating;
            // Fullscreen shows the cover clear, so a blurred one asks first.
            if (rating != null &&
                WidgetUtils.isRatingBlurred(rating) &&
                !await confirmUnblur(context)) {
              return;
            }
            if (!context.mounted) return;
            final allUrls = widget.allCovers
                .map((c) => c.url ?? c.urlX350 ?? c.urlX250 ?? c.urlX150)
                .whereType<String>()
                .toList();

            final initialIndex = widget.allCovers.indexOf(widget.cover);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageScreen(
                  imageUrls: allUrls,
                  initialIndex: initialIndex,
                  heroTag: widget.url!,
                  titles: widget.allTitles,
                  notes: widget.allNotes,
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: _hovered && widget.url != null
                      ? Border.all(
                          color: context.colors.accent.withValues(alpha: 0.6),
                          width: 2,
                        )
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widget.url != null
                      ? Hero(
                          tag: widget.url!,
                          child: ListenableBuilder(
                            listenable: SettingsManager(),
                            builder: (context, _) {
                              final isBlurred =
                                  widget.contentRating != null &&
                                  SettingsManager().blurredContentRatings
                                      .contains(
                                        widget.contentRating!.toLowerCase(),
                                      );
                              return WidgetUtils.networkImage(
                                url: widget.url!,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                                blurred: isBlurred,
                              );
                            },
                          ),
                        )
                      : Container(
                          color: context.colors.surface,
                          child: const Icon(Icons.broken_image),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
