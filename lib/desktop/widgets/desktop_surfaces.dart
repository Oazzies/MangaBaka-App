import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
export 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';

/// The title block every desktop page opens with: a large display-caps title,
/// an optional muted subtitle, and right-aligned actions on the same line.
///
/// Replaces the phone's centred app bar, which on a wide window left a title
/// floating in the middle of an empty strip.
class DesktopPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Shown before the title — a back button on pushed pages.
  final Widget? leading;

  final EdgeInsetsGeometry padding;

  const DesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(
      DesktopTokens.pagePadding,
      10,
      DesktopTokens.pagePadding,
      16,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final double additionalRight = DesktopLayout.isDesktopPlatform
        ? (DesktopTokens.windowControlsClearance - resolvedPadding.right).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;
    final effectivePadding = resolvedPadding.add(
      EdgeInsets.only(right: additionalRight),
    );

    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 30,
            height: 1.1,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: effectivePadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (actions.isEmpty) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(child: titleWidget),
              ],
            );
          }

          if (constraints.maxWidth < 540) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: titleWidget),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(child: titleWidget),
              const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A rounded, flat panel — the desktop's one card surface.
class DesktopCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool showBorder;

  const DesktopCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
        border: showBorder ? Border.all(color: context.colors.border) : null,
      ),
      child: child,
    );
  }
}

/// Small caps label over a block of content, with optional trailing controls.
class DesktopSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const DesktopSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize = 18,
    this.padding = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.display(
        color: context.colors.text,
        fontSize: fontSize,
      ),
    );

    if (trailing == null) {
      return Padding(padding: padding, child: titleWidget);
    }

    return Padding(
      padding: padding,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [titleWidget, trailing!],
      ),
    );
  }
}

/// A clickable surface that lightens under the pointer.
///
/// Phone screens rely on ink splashes, which a mouse user only sees after
/// committing to a click; on desktop the hover state is the affordance.
class DesktopHoverSurface extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final bool selected;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Fill when neither hovered nor selected.
  final Color? idleColor;
  final Color? hoverColor;
  final Color? selectedColor;
  final String? tooltip;

  const DesktopHoverSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onSecondaryTap,
    this.selected = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = EdgeInsets.zero,
    this.idleColor,
    this.hoverColor,
    this.selectedColor,
    this.tooltip,
  });

  @override
  State<DesktopHoverSurface> createState() => _DesktopHoverSurfaceState();
}

class _DesktopHoverSurfaceState extends State<DesktopHoverSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? (widget.selectedColor ?? context.colors.surfaceRaised)
        : _hovered
        ? (widget.hoverColor ?? context.colors.surfaceRaised)
        : (widget.idleColor ?? Colors.transparent);

    Widget child = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null &&
        widget.tooltip!.isNotEmpty &&
        SettingsManager().showTooltips) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}

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
          Text(
            label.toUpperCase(),
            style: AppTypography.display(color: fg, fontSize: 12.5),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

/// A one-of-many choice as a row of joined segments.
class DesktopSegmented<T> extends StatelessWidget {
  final List<(T, String?, IconData?)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Tooltip per segment, for icon-only segments.
  final String Function(T value)? tooltipFor;

  const DesktopSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.tooltipFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (segment, label, icon) in segments)
            _Segment(
              label: label,
              icon: icon,
              selected: segment == value,
              tooltip: tooltipFor?.call(segment),
              onTap: () => onChanged(segment),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final String? tooltip;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onAccent : context.colors.textMuted;
    return DesktopHoverSurface(
      onTap: onTap,
      tooltip: tooltip,
      selected: selected,
      selectedColor: context.colors.accent,
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: EdgeInsets.symmetric(
        horizontal: label == null ? 10 : 14,
        vertical: 7,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 17, color: fg),
          if (icon != null && label != null) const SizedBox(width: 6),
          if (label != null)
            Text(
              label!.toUpperCase(),
              style: AppTypography.display(color: fg, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// A dropdown shown as an expanding pill that seamlessly opens into the menu.
class DesktopMenuButton<T> extends StatelessWidget {
  final String? label;
  final String valueLabel;
  final IconData? icon;
  final List<(T, String)> items;
  final T? selected;
  final ValueChanged<T> onSelected;

  const DesktopMenuButton({
    super.key,
    this.label,
    required this.valueLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopDropdown<T>(
      label: label,
      valueLabel: valueLabel,
      icon: icon,
      items: [
        for (final (value, text) in items)
          DesktopDropdownItem<T>(value: value, label: text),
      ],
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Centered icon + message, for empty and error states.
class DesktopEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const DesktopEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: context.colors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 15,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// The left-hand panel of a two-pane page: fixed width, its own scroll, and a
/// hairline against the content.
class DesktopSidePanel extends StatelessWidget {
  final Widget child;
  final double width;

  const DesktopSidePanel({
    super.key,
    required this.child,
    this.width = DesktopTokens.panelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(right: BorderSide(color: context.colors.border)),
      ),
      child: child,
    );
  }
}

/// One row of a desktop settings card: a muted glyph, a display-caps title with
/// its explanation beneath, and the control on the right.
class DesktopSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget control;

  const DesktopSettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Icon(icon, color: context.colors.textMuted, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        control,
      ],
    );
  }
}
