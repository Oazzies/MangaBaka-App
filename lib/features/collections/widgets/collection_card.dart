import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// One collection: its title, who published it as which edition, and the
/// format/medium/status badges. Tapping opens the collection's works.
///
/// Shared by the series' Collections tab and the collections browser so a
/// collection looks the same wherever it turns up.
class CollectionCard extends StatelessWidget {
  final SeriesCollection collection;
  final VoidCallback? onTap;

  /// Names the publisher in the byline; the browser turns it off because the
  /// publisher is already the page's subject.
  final bool showPublisher;

  const CollectionCard({
    super.key,
    required this.collection,
    this.onTap,
    this.showPublisher = true,
  });

  @override
  Widget build(BuildContext context) {
    final col = collection;
    final byline = [
      if (showPublisher && col.publisherName.isNotEmpty) col.publisherName,
      if (col.editionName.isNotEmpty) col.editionName,
      if (col.languageName.isNotEmpty) col.languageName,
    ].join('  ·  ');

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.title,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (byline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        byline,
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (col.countMain > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${col.countMain} VOLS',
                  style: AppTypography.monoLabel(
                    color: context.colors.accent,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(col.format),
              _Badge(col.medium),
              _Badge(col.status),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return MbTappable(onTap: onTap, pressedScale: 0.985, child: card);
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
