import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Thin amber progress track, as used under the reference's "NOW" hero.
class MbProgressBar extends StatelessWidget {
  /// Clamped to 0..1. Null renders an empty track (unknown progress).
  final double? value;
  final double height;

  const MbProgressBar({super.key, required this.value, this.height = 3});

  @override
  Widget build(BuildContext context) {
    final v = (value ?? 0).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: context.colors.surfaceRaised,
        valueColor: AlwaysStoppedAnimation(context.colors.accent),
      ),
    );
  }
}
