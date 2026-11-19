import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  final double gap;

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
