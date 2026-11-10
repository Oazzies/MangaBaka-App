import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// A dashed rectangle border whose dashes can be animated to crawl —
/// "marching ants" — by driving [phase] from an [AnimationController].
///
/// Used to frame the screen while the series detail filter drawer is open, so
/// it reads as a temporary mode rather than a normal sheet.
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  /// Length of a gap. Dashes are drawn at twice this, giving a 2:1 rhythm.
  final double gap;

  /// Offset into the dash pattern, in logical pixels. Animating it upward
  /// makes the dashes travel; it repeats every `gap * 3`.
  final double phase;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Inset by half the stroke so the border sits fully inside the bounds
    // instead of being clipped along its outer edge.
    final path = Path()
      ..addRect(
        Rect.fromLTWH(
          strokeWidth / 2,
          strokeWidth / 2,
          size.width - strokeWidth,
          size.height - strokeWidth,
        ),
      );

    final dashLength = gap * 2;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = phase % (gap * 3);
      var draw = true;
      while (distance < metric.length) {
        final segment = draw ? dashLength : gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + segment),
            paint,
          );
        }
        distance += segment;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap;
}
