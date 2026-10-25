import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_cover.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';

/// A stack's preview: up to four covers laid over one another like a fanned
/// pile, the first on top. Empty slots show as wells so every card in a row
/// has the same silhouette.
///
/// Sized by its parent's width; the height follows from the cover ratio.
class StackCoverFan extends StatelessWidget {
  final List<StackCover> covers;

  /// The stack's rating; covers are blurred when the user blurs it.
  final String contentRating;

  /// Slots drawn, filled or not.
  static const int slots = 4;

  /// Share of the width each further cover is shifted right by.
  static const double _step = 0.16;

  /// Height of the fan for a given width.
  static double heightFor(double width) {
    final coverWidth = width / (1 + _step * (slots - 1));
    return coverWidth * 1.5;
  }

  const StackCoverFan({
    super.key,
    required this.covers,
    this.contentRating = 'safe',
  });

  @override
  Widget build(BuildContext context) {
    final blurred = WidgetUtils.isRatingBlurred(contentRating);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final coverWidth = width / (1 + _step * (slots - 1));
        final height = coverWidth * 1.5;
        final decode = WidgetUtils.decodeWidth(context, coverWidth);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Back to front, so the first cover ends up on top.
              for (var i = slots - 1; i >= 0; i--)
                Positioned(
                  left: coverWidth * _step * i,
                  top: 0,
                  child: Transform.scale(
                    scale: 1 - 0.06 * i,
                    alignment: Alignment.centerLeft,
                    child: _Slot(
                      width: coverWidth,
                      cover: i < covers.length ? covers[i] : null,
                      depth: i,
                      blurred: blurred,
                      decodeWidth: decode,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  final double width;
  final StackCover? cover;
  final int depth;
  final bool blurred;
  final int decodeWidth;
  const _Slot({
    required this.width,
    required this.cover,
    required this.depth,
    required this.blurred,
    required this.decodeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = math.max(8.0, width * 0.08);
    final cover = this.cover;
    return _body(c, radius, cover);
  }

  Widget _body(dynamic c, double radius, StackCover? cover) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(-3, 3),
          ),
        ],
      ),
      child: cover == null
          ? Container(
              width: width,
              height: width * 1.5,
              decoration: BoxDecoration(
                color: Color.lerp(c.surfaceRaised, c.surface, depth / 4),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: c.border),
              ),
            )
          // Covers further back are shaded rather than faded: no saveLayer.
          : DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: c.background.withValues(alpha: depth * 0.12),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: MbCover(
                url: cover.url,
                width: width,
                radius: radius,
                memCacheWidth: decodeWidth,
                blurred: blurred,
              ),
            ),
    );
  }
}
