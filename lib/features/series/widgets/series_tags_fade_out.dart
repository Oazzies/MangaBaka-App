import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Bottom fade-out gradient for clipped tag/metadata sections.
class SeriesTagsFadeOut extends StatelessWidget {
  const SeriesTagsFadeOut({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.surface.withValues(alpha: 0),
              context.colors.surface,
            ],
          ),
        ),
      ),
    );
  }
}
