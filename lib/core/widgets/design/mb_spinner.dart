import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// MangaBaka's signature progress spinner: a kinetic rotating rounded square.
///
/// Distinctive Manga Design:
/// - A stylized rounded square reflecting MangaBaka's rounded card and cover
///   geometry.
/// - In indeterminate mode, it rotates with kinetic momentum while its stroke
///   sweeps dynamically around the rounded square perimeter.
/// - In determinate mode, an elegant solid track in [surfaceRaised] fills
///   progress precisely from 0% to 100% along the rounded square contour.
/// - Uses 100% solid theme colors with no washed-out transparencies.
class MbSpinner extends StatefulWidget {
  final double size;
  final double? strokeWidth;
  final Color? color;
  final Color? trackColor;
  final double? value;

  const MbSpinner({
    super.key,
    this.size = 24.0,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.value,
  });

  @override
  State<MbSpinner> createState() => _MbSpinnerState();
}

class _MbSpinnerState extends State<MbSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );

  @override
  void initState() {
    super.initState();
    if (widget.value == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MbSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    } else if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.accent;
    final trackColor = widget.trackColor ??
        (widget.value != null ? context.colors.surfaceRaised : null);
    final strokeWidth =
        widget.strokeWidth ?? (widget.size * 0.11).clamp(2.0, 3.8);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _MbSpinnerPainter(
            progress: widget.value ?? _controller.value,
            isDeterminate: widget.value != null,
            color: color,
            trackColor: trackColor,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _MbSpinnerPainter extends CustomPainter {
  final double progress;
  final bool isDeterminate;
  final Color color;
  final Color? trackColor;
  final double strokeWidth;

  const _MbSpinnerPainter({
    required this.progress,
    required this.isDeterminate,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height) - strokeWidth;
    if (side <= 0) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final cornerRadius = (side * 0.24).clamp(3.0, 10.0);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    final basePath = Path()..addRRect(rrect);
    final metrics = basePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final totalLength = metric.length;

    // 1. Optional solid track (rendered in determinate mode or when explicitly set)
    if (trackColor != null) {
      final trackPaint = Paint()
        ..color = trackColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRRect(rrect, trackPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    // 2. Determinate mode: progress fills along rounded square perimeter
    if (isDeterminate) {
      final clampedProgress = progress.clamp(0.0, 1.0);
      if (clampedProgress > 0.0) {
        // Start from top-center
        final straightTopHalf = (rect.width - 2 * cornerRadius) / 2.0;
        final startOffset = straightTopHalf.clamp(0.0, totalLength);
        final sweepLength = clampedProgress * totalLength;
        final path = _extractSubPath(metric, totalLength, startOffset, sweepLength);
        canvas.drawPath(path, strokePaint);
      }
      return;
    }

    // 3. Indeterminate mode: kinetic rotating rounded square
    final t = progress;
    // Rotation around center
    final rotation = t * 2 * math.pi;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Dynamic sweeping stroke along the rounded square perimeter:
    // Expands and contracts between ~30% and ~85% of total perimeter
    final sweepSine =
        (math.sin(t * 2 * math.pi - (math.pi / 2)) + 1.0) / 2.0;
    final sweepLength = totalLength * (0.30 + 0.55 * sweepSine);
    final startOffset = (t * 1.35 * totalLength) % totalLength;

    final sweepPath =
        _extractSubPath(metric, totalLength, startOffset, sweepLength);
    canvas.drawPath(sweepPath, strokePaint);
    canvas.restore();
  }

  Path _extractSubPath(
    PathMetric metric,
    double totalLength,
    double start,
    double length,
  ) {
    if (totalLength <= 0 || length <= 0) return Path();
    final clampedLength = length.clamp(0.0, totalLength);
    final normalizedStart = start % totalLength;
    final end = normalizedStart + clampedLength;

    if (end <= totalLength) {
      return metric.extractPath(normalizedStart, end);
    } else {
      final p1 = metric.extractPath(normalizedStart, totalLength);
      final p2 = metric.extractPath(0.0, end - totalLength);
      return Path()
        ..addPath(p1, Offset.zero)
        ..addPath(p2, Offset.zero);
    }
  }

  @override
  bool shouldRepaint(covariant _MbSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDeterminate != isDeterminate;
  }
}
