part of 'desktop_surfaces.dart';

/// A round icon button with a hover fill, sized for a pointer.
class DesktopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool filled;

  const DesktopIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 20,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DesktopHoverSurface(
      onTap: onPressed,
      tooltip: tooltip,
      idleColor: filled ? context.colors.surfaceRaised : null,
      hoverColor: filled ? context.colors.border : context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.all(10),
      child: Icon(
        icon,
        size: size,
        color: enabled
            ? (color ?? context.colors.text)
            : context.colors.textMuted.withValues(alpha: 0.4),
      ),
    );
  }
}

/// A pill-shaped labelled button — the desktop toolbar's secondary action.
class DesktopPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;

  /// A destructive action (sign out, delete): tinted and lettered in the app's
  /// error red instead of neutral, so it reads as one without shouting.
  final bool danger;
  final Widget? trailing;
  final String? tooltip;

  /// The fill of a [danger] button, and its hover: the error red at low
  /// strength, on the same footing as the neutral pill it replaces.
  static Color dangerColor(MbPalette c) => c.error.withValues(alpha: 0.16);
  static Color dangerHoverColor(MbPalette c) => c.error.withValues(alpha: 0.28);

  const DesktopPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.trailing,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? context.colors.error
        : primary
        ? context.colors.onAccent
        : context.colors.text;
    return DesktopHoverSurface(
      onTap: onPressed,
      tooltip: tooltip,
      idleColor: danger
          ? dangerColor(context.colors)
          : primary
          ? context.colors.accent
          : context.colors.surfaceRaised,
      hoverColor: danger
          ? dangerHoverColor(context.colors)
          : primary
          ? context.colors.hoverOf(context.colors.accent)
          : context.colors.border,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 8),
          ],
          // Flexible: its natural width wherever there's room, but a pill
          // squeezed narrower than its (translated, text-scaled) label
          // ellipsises instead of overflowing.
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(color: fg, fontSize: 12.5),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}
