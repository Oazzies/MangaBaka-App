import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// One editable colour: swatch, name, hex, and an optional "auto" reset for
/// the tokens that are derived unless the user overrides them.
class ThemeColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool? isAuto;
  final VoidCallback? onAuto;

  const ThemeColorRow({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.isAuto,
    this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Outlined rather than filled: the rows sit on the page background on
      // phones but on a surface-coloured dialog on desktop.
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.sans(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isAuto == true
                            ? l10n.translate('theme_auto_hint')
                            : ColorMath.toHex(color),
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuto != null)
                  _AutoChip(active: isAuto!, onTap: isAuto! ? null : onAuto),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoChip extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _AutoChip({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.accent : c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Text(
          LocalizationService().translate('theme_auto').toUpperCase(),
          style: AppTypography.display(
            color: active ? c.onAccent : c.textMuted,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
