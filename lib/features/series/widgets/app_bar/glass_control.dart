import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A frosted-glass control floating on the series banner: a labelled pill for
/// "Back", or a circular icon button for share and delete.
///
/// The two were separate widgets that differed only in shape and size while
/// carrying identical copies of the blur, clip, ink and background logic —
/// including the two conditions that make the blur safe to draw.
class GlassControl extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  /// Text beside the icon. Null makes the control a circle sized to [size].
  final String? label;

  /// Whether the control has a visible background at all.
  ///
  /// It is dropped once the page has scrolled far enough that the control sits
  /// on the solid app bar rather than on the artwork — a glass pill on a flat
  /// background reads as a stray box.
  final bool showBg;

  /// Gate for the backdrop blur, held off during the route transition.
  ///
  /// A [BackdropFilter] cannot be raster-cached, so an active one forces a
  /// full re-render on every frame of the slide.
  final bool blurEnabled;

  /// Diameter when unlabelled; the height in both cases.
  final double size;

  final double iconSize;

  const GlassControl({
    super.key,
    required this.onTap,
    required this.icon,
    this.label,
    this.showBg = true,
    this.blurEnabled = true,
    this.size = 40,
    this.iconSize = 19,
  });

  static final BorderRadius _radius = BorderRadius.circular(999);

  @override
  Widget build(BuildContext context) {
    // Blurring a transparent background costs the same as blurring a visible
    // one and shows nothing, so it is skipped along with the background.
    final useBlur = showBg && blurEnabled;

    final Widget body = Container(
      height: size,
      width: label == null ? size : null,
      padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
      decoration: BoxDecoration(
        color: showBg
            ? context.colors.surface.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: _radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: context.colors.text),
          if (label != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label!,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: ClipRRect(
          borderRadius: _radius,
          child: useBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: body,
                )
              : body,
        ),
      ),
    );
  }
}
