import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// One seed in the Mix seed row: cover thumbnail, title, and a remove button.
///
/// Tapping the chip body opens the series; only the trailing circle removes
/// it, so a mis-tap costs a navigation rather than losing a seed.
class MixSeedChip extends StatelessWidget {
  final Series seed;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const MixSeedChip({
    super.key,
    required this.seed,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Thumbnail(url: seed.coverUrl),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    seed.title,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _RemoveButton(onTap: onRemove),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: 50,
        child: url.isNotEmpty
            // Decoded at 80px rather than full size: the chip is 36px wide, and
            // full-resolution covers in a horizontal row is real memory on a
            // low-end device.
            ? WidgetUtils.networkImage(
                url: url,
                fit: BoxFit.cover,
                memCacheWidth: 80,
              )
            : Container(
                color: context.colors.surfaceRaised,
                child: Icon(
                  Icons.book_rounded,
                  color: context.colors.accent,
                  size: 18,
                ),
              ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          color: context.colors.textMuted,
          size: 13,
        ),
      ),
    );
  }
}
