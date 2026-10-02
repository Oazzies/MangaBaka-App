import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// What a toast is telling the user; picks its glyph and, for errors, its fill.
enum ToastKind { success, error, warning, info }

extension ToastKindStyle on ToastKind {
  /// The colour of the glyph disc.
  Color tone(MbPalette c) => switch (this) {
        ToastKind.success => c.success,
        ToastKind.error => c.error,
        ToastKind.warning => c.warning,
        ToastKind.info => c.accent,
      };

  IconData get icon => switch (this) {
        ToastKind.success => Icons.check_rounded,
        ToastKind.error => Icons.priority_high_rounded,
        ToastKind.warning => Icons.warning_amber_rounded,
        ToastKind.info => Icons.info_outline_rounded,
      };
}

/// The solid colours a toast is drawn in. Nothing here is translucent: the
/// card is filled with the theme's accent, so it belongs to whichever theme is
/// active and stands clear of what it floats over. Errors take the error
/// colour instead.
class ToastColors {
  final Color fill;
  final Color ink;

  /// A quieter ink for the detail line, blended into the fill rather than
  /// made see-through.
  final Color inkMuted;

  /// The glyph disc, and the ink drawn on it.
  final Color disc;
  final Color onDisc;

  /// The action pill and its label.
  final Color action;
  final Color onAction;

  const ToastColors._({
    required this.fill,
    required this.ink,
    required this.inkMuted,
    required this.disc,
    required this.onDisc,
    required this.action,
    required this.onAction,
  });

  factory ToastColors.of(MbPalette c, ToastKind kind) {
    if (kind == ToastKind.error) {
      final fill = c.error;
      final ink = c.on(fill);
      return ToastColors._(
        fill: fill,
        ink: ink,
        inkMuted: Color.lerp(fill, ink, 0.82)!,
        // Inverted on the red: a light disc carrying a red glyph.
        disc: ink,
        onDisc: fill,
        action: ink,
        onAction: fill,
      );
    }
    // The theme's accent as the fill (orange in Tako, green in the default
    // theme, ...) with its own on-accent ink. The glyph disc and the action
    // pill are the inverse — ink-coloured, carrying fill-coloured marks — so
    // they stand out from the fill.
    final fill = c.accent;
    final ink = c.onAccent;
    return ToastColors._(
      fill: fill,
      ink: ink,
      inkMuted: Color.lerp(fill, ink, 0.78)!,
      disc: ink,
      onDisc: fill,
      action: ink,
      onAction: fill,
    );
  }
}

/// The app's one floating-notification surface: a solid pill with a glyph disc,
/// a title (and optional detail line), an optional action, and an optional
/// strip beneath (a progress bar). Snackbars and the library sync card are both
/// built from it so every transient message looks like the same component.
class MbToastCard extends StatelessWidget {
  final ToastKind kind;

  /// Replaces the default glyph disc — e.g. with a spinner while syncing.
  final Widget? leading;
  final IconData? icon;
  final String title;
  final String? detail;

  /// Trailing controls: an action pill, a close button.
  final List<Widget> trailing;

  /// Full-width content under the text row, such as a progress bar.
  final Widget? footer;

  final VoidCallback? onTap;
  final double? maxWidth;
  final double radius;

  const MbToastCard({
    super.key,
    required this.title,
    this.kind = ToastKind.info,
    this.leading,
    this.icon,
    this.detail,
    this.trailing = const [],
    this.footer,
    this.onTap,
    this.maxWidth,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = ToastColors.of(colors, kind);

    Widget card = Container(
      constraints: maxWidth == null ? null : BoxConstraints(maxWidth: maxWidth!),
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: t.fill,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.shadowAt(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading ??
                  ToastBadge(
                    icon: icon ?? kind.icon,
                    disc: t.disc,
                    onDisc: t.onDisc,
                  ),
              const SizedBox(width: 12),
              // Expanded when there is something trailing, so it sits at the
              // card's right edge rather than hugging the text.
              _fit(
                expand: trailing.isNotEmpty,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: t.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (detail != null && detail!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: t.inkMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (final w in trailing) ...[const SizedBox(width: 12), w],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );

    if (onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

Widget _fit({required bool expand, required Widget child}) =>
    expand ? Expanded(child: child) : Flexible(child: child);

/// The round glyph disc at a toast's leading edge — a solid colour with the
/// glyph in legible ink on it.
class ToastBadge extends StatelessWidget {
  final IconData icon;
  final Color disc;
  final Color onDisc;
  final double size;

  const ToastBadge({
    super.key,
    required this.icon,
    required this.disc,
    required this.onDisc,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.55, color: onDisc),
    );
  }
}

/// A compact solid pill for a toast's action ("Undo", "Settings", "Stop").
/// Pass the toast's [kind] so the pill is drawn in colours that read on it.
class ToastActionPill extends StatelessWidget {
  final String label;
  final ToastKind kind;
  final VoidCallback onPressed;
  final IconData? icon;

  const ToastActionPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ToastKind.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = ToastColors.of(context.colors, kind);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: t.action,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.display(color: t.onAction, fontSize: 12),
              ),
              if (icon != null) ...[
                const SizedBox(width: 5),
                Icon(icon, size: 14, color: t.onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
