import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Uppercase pill — the design system's single selectable-chip shape.
///
/// Selected reads as a solid amber fill with ink-black caps; unselected is a
/// flat dark well with white caps. Used for browse type tabs, filter chips and
/// any other one-of-many choice.
class MbPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;

  /// Shown as a small count/qualifier after the label (e.g. an active filter
  /// count). Rendered in the same ink as the label at reduced opacity.
  final String? trailingText;

  /// Fills the available width with the content centred — for a row of
  /// equal-width segments. Tightens the padding and ellipsises the label so
  /// three segments still fit a phone.
  final bool expand;

  const MbPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.trailingText,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onAccent : context.colors.text;
    final labelText = AnimatedDefaultTextStyle(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      style: AppTypography.display(color: fg, fontSize: 13),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return MbTappable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.accent
              : context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expand ? 10 : 18,
            vertical: 11,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 7),
              ],
              // Flexible only when expanding: pills also sit in horizontal
              // scroll strips, where the width is unbounded.
              if (expand) Flexible(child: labelText) else labelText,
              if (trailingText != null) ...[
                const SizedBox(width: 6),
                Text(
                  trailingText!,
                  style: AppTypography.display(
                    color: fg.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of [MbPill]s, matching the reference's genre
/// tab strip. Bleeds to the screen edge so the strip reads as scrollable.
class MbPillStrip extends StatelessWidget {
  final List<Widget> pills;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  const MbPillStrip({
    super.key,
    required this.pills,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppConstants.horizontalPadding,
    ),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            pills[i],
          ],
        ],
      ),
    );
  }
}
