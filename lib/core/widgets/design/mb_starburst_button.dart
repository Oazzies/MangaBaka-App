import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Draws the reference's hand-cut amber starburst: a closed polygon whose
/// radius alternates between an outer spike and an inner valley, with a small
/// deterministic jitter per vertex so it reads as drawn rather than generated.
class _StarburstPainter extends CustomPainter {
  final Color color;
  final int spikes;

  const _StarburstPainter({required this.color, required this.spikes});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();

    // Jitter is derived from the vertex index, so the shape is stable across
    // rebuilds (no Random instance, no animation flicker).
    double jitter(int i) => 1.0 + 0.06 * math.sin(i * 2.399963);

    for (var i = 0; i < spikes * 2; i++) {
      final isSpike = i.isEven;
      final angle = (math.pi * i) / spikes - math.pi / 2;
      // Ellipse radii keep the burst proportional to a wide, short button.
      final rx = (isSpike ? cx : cx * 0.86) * jitter(i);
      final ry = (isSpike ? cy : cy * 0.62) * jitter(i + 1);
      final p = Offset(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarburstPainter old) =>
      old.color != color || old.spikes != spikes;
}

/// Amber starburst CTA — the loudest button in the app. Reserved for the one
/// primary action on a series detail screen; everything quieter should use
/// [MbPrimaryButton].
class MbStarburstButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final int spikes;

  /// Inset between the label and the spikes. The default suits a full-width
  /// hero CTA; a floating action wants something tighter.
  final EdgeInsetsGeometry padding;

  const MbStarburstButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.spikes = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 46, vertical: 30),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled
        ? context.colors.accent
        : context.colors.accent.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: MbTappable(
        onTap: onPressed,
        pressedScale: 0.93,
        child: CustomPaint(
          painter: _StarburstPainter(color: color, spikes: spikes),
          child: Padding(
            // Inset so the label clears the spikes on every side.
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.onAccent,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, size: 19, color: context.colors.onAccent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
