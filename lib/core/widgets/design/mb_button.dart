import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Solid amber pill CTA with ink-black uppercase caps — the reference's
/// "CONTINUE READING" button. The app's single primary action shape.
class MbPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Trailing icon instead of leading (e.g. an arrow on a "go" action).
  final IconData? trailingIcon;
  final bool expand;
  final bool busy;

  const MbPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bg = enabled
        ? context.colors.accent
        : context.colors.accent.withValues(alpha: 0.35);

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(context.colors.onAccent),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: context.colors.onAccent),
        if (busy || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              color: context.colors.onAccent,
              fontSize: 15,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(trailingIcon, size: 18, color: context.colors.onAccent),
        ],
      ],
    );

    return MbTappable(
      onTap: enabled ? onPressed : null,
      pressedScale: 0.975,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: row,
      ),
    );
  }
}

/// Quiet counterpart to [MbPrimaryButton]: same pill, dark well, white caps.
/// For secondary actions that sit beside a primary one.
class MbSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const MbSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return MbTappable(
      onTap: onPressed,
      pressedScale: 0.975,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: context.colors.text),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
