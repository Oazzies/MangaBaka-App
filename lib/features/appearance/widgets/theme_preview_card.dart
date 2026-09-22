import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A selectable miniature of the app drawn in [palette] — not the active
/// theme — so a gallery of these shows every theme side by side.
///
/// The frame (selection ring, label) uses the *active* theme, since it is part
/// of the screen the gallery sits on, not of the theme being previewed.
class ThemePreviewCard extends StatelessWidget {
  final MbPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Long-press on touch, right-click on desktop. Used for custom themes'
  /// edit/share/delete menu.
  final void Function(Offset globalPosition)? onMenu;

  /// Small marker in the corner, e.g. a pencil on custom themes.
  final IconData? badge;

  final double width;

  const ThemePreviewCard({
    super.key,
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onMenu,
    this.badge,
    this.width = 112,
  });

  static const double aspect = 1.3;

  @override
  Widget build(BuildContext context) {
    final frame = context.colors;
    final height = width * aspect;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onLongPressStart: onMenu == null
            ? null
            : (d) => onMenu!(d.globalPosition),
        onSecondaryTapUp: onMenu == null
            ? null
            : (d) => onMenu!(d.globalPosition),
        child: MbTappable(
          onTap: onTap,
          pressedScale: 0.96,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  width: width,
                  height: height,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? frame.accent : frame.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(child: ThemeMiniature(palette: palette)),
                        if (badge != null || selected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _Marker(
                              icon: selected ? Icons.check_rounded : badge!,
                              fill: selected ? frame.accent : palette.surface,
                              ink: selected ? frame.onAccent : palette.text,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(
                    color: selected ? frame.text : frame.textMuted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final IconData icon;
  final Color fill;
  final Color ink;

  const _Marker({required this.icon, required this.fill, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(icon, size: 13, color: ink),
    );
  }
}

/// The mock screen inside a [ThemePreviewCard]: a header, a pill strip, a
/// row of covers and a nav bar — the four things that define how the app
/// looks, reduced to blocks. Scales to whatever box it is given.
class ThemeMiniature extends StatelessWidget {
  final MbPalette palette;

  const ThemeMiniature({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return LayoutBuilder(
      builder: (context, box) {
        final u = box.maxWidth / 100; // one "unit" = 1% of the width
        Widget bar(double w, double h, Color c, [double r = 99]) => Container(
          width: w * u,
          height: h * u,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(r * u),
          ),
        );

        return ColoredBox(
          color: p.background,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8 * u, 9 * u, 8 * u, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: title caps + an avatar dot.
                Row(
                  children: [
                    bar(40, 7, p.text, 2),
                    const Spacer(),
                    bar(9, 9, p.surfaceRaised),
                  ],
                ),
                SizedBox(height: 8 * u),
                // Pill strip: the accent "on" state next to a quiet one.
                Row(
                  children: [
                    bar(24, 9, p.accent),
                    SizedBox(width: 4 * u),
                    bar(20, 9, p.surfaceRaised),
                    SizedBox(width: 4 * u),
                    bar(16, 9, p.surfaceRaised),
                  ],
                ),
                SizedBox(height: 8 * u),
                // Covers with title lines.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) SizedBox(width: 4 * u),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 0.7,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: i == 0 ? p.surfaceRaised : p.surface,
                                    borderRadius: BorderRadius.circular(4 * u),
                                    border: Border.all(
                                      color: p.border,
                                      width: 0.6,
                                    ),
                                  ),
                                  alignment: Alignment.bottomLeft,
                                  padding: EdgeInsets.all(2.5 * u),
                                  child: i == 0
                                      ? bar(10, 3.5, p.star)
                                      : null,
                                ),
                              ),
                              SizedBox(height: 3 * u),
                              bar(22, 3.5, p.text.withValues(alpha: 0.85)),
                              SizedBox(height: 2 * u),
                              bar(14, 3, p.textMuted),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Nav bar with the active destination in accent.
                Container(
                  margin: EdgeInsets.only(bottom: 6 * u),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * u,
                    vertical: 4 * u,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: p.border, width: 0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      bar(14, 6, p.accent),
                      bar(6, 6, p.textMuted),
                      bar(6, 6, p.textMuted),
                      bar(6, 6, p.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
