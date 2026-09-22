import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/features/appearance/widgets/mb_color_picker.dart';

/// Row of accent swatches: "theme default", the curated accents, and a custom
/// colour. The override applies on top of whichever theme is active, and is
/// contrast-adjusted per theme by the controller.
class AccentPicker extends StatelessWidget {
  final double swatchSize;

  const AccentPicker({super.key, this.swatchSize = 36});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController();
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final override = controller.accentOverride;
        final isCustom = override != null &&
            !ThemePresets.accentSwatches.contains(override);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AccentSwatch(
              size: swatchSize,
              tooltip: l10n.translate('accent_theme_default'),
              selected: override == null,
              onTap: () => controller.setAccentOverride(null),
              child: _DefaultGlyph(size: swatchSize),
            ),
            for (final s in ThemePresets.accentSwatches)
              _AccentSwatch(
                size: swatchSize,
                color: s,
                selected: override == s,
                onTap: () => controller.setAccentOverride(s),
              ),
            _AccentSwatch(
              size: swatchSize,
              tooltip: l10n.translate('accent_custom'),
              color: isCustom ? override : null,
              selected: isCustom,
              onTap: () async {
                final picked = await showMbColorPicker(
                  context,
                  initial: override ?? context.colors.accent,
                  title: l10n.translate('accent_custom'),
                  contrastAgainst: context.colors.surface,
                );
                if (picked != null) controller.setAccentOverride(picked);
              },
              child: isCustom
                  ? null
                  : Icon(
                      Icons.colorize_rounded,
                      size: swatchSize * 0.5,
                      color: context.colors.text,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final double size;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;
  final Widget? child;

  const _AccentSwatch({
    required this.size,
    required this.selected,
    required this.onTap,
    this.color,
    this.tooltip,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = color ?? c.surfaceRaised;
    Widget swatch = MbTappable(
      onTap: onTap,
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        width: size,
        height: size,
        padding: EdgeInsets.all(selected ? 3 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.text : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: child ??
              (selected
                  ? Icon(Icons.check_rounded, size: size * 0.45, color: c.on(fill))
                  : null),
        ),
      ),
    );
    if (tooltip != null) swatch = Tooltip(message: tooltip!, child: swatch);
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: swatch,
    );
  }
}

/// Half the active theme's own accent, half a diagonal slash — "whatever the
/// theme uses".
class _DefaultGlyph extends StatelessWidget {
  final double size;
  const _DefaultGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Icon(Icons.format_color_reset_rounded, size: size * 0.5, color: c.text);
  }
}
