import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/fixed_colors.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Always builds the same tree, so entering selection never remounts the item under it.
class SelectableEntryFrame extends StatelessWidget {
  final bool selecting;
  final bool selected;
  final Widget child;

  const SelectableEntryFrame({
    super.key,
    required this.selecting,
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? c.accent : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 6,
            left: 6,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: selecting ? 1 : 0,
                duration: AppMotion.fast,
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? FixedColors.imageBadge
                        : FixedColors.imageScrim.withValues(alpha: 0.35),
                    border: Border.all(color: FixedColors.onImage, width: 2),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: FixedColors.onImage,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
