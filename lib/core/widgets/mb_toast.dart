import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

enum ToastKind { success, error, warning, info }

extension ToastKindStyle on ToastKind {
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

/// Never translucent, so the toast stands clear of what it floats over.
class ToastColors {
  final Color fill;
  final Color ink;

  final Color inkMuted;

  final Color disc;
  final Color onDisc;

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
        disc: ink,
        onDisc: fill,
        action: ink,
        onAction: fill,
      );
    }
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

class MbToastCard extends StatelessWidget {
  final ToastKind kind;

  final Widget? leading;
  final IconData? icon;
  final String title;
  final String? detail;

  final List<Widget> trailing;

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
      constraints: maxWidth == null
          ? null
          : BoxConstraints(maxWidth: maxWidth!),
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
