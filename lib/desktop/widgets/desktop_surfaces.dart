import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/fit_or_else.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
export 'package:mangabaka_app/desktop/widgets/desktop_dropdown.dart';

part 'desktop_surface_buttons_part.dart';
part 'desktop_surface_controls_part.dart';

/// The title block every desktop page opens with: a large display-caps title,
/// an optional muted subtitle, and right-aligned actions on the same line.
///
/// Replaces the phone's centred app bar, which on a wide window left a title
/// floating in the middle of an empty strip.
class DesktopPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Shown before the title â€” a back button on pushed pages.
  final Widget? leading;

  final EdgeInsetsGeometry padding;

  /// False when something at least [DesktopTokens.windowControlsClearance]
  /// wide (e.g. a trailing sidebar) already sits to this header's right, up
  /// to the window's real right edge â€” the custom window controls then
  /// float over that, not over the header, so it doesn't need its own
  /// clearance padding pushing its actions away from its own right edge.
  final bool reserveWindowControls;

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
    this.reserveWindowControls = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final double additionalRight =
        DesktopLayout.isDesktopPlatform && reserveWindowControls
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

    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: titleWidget),
      ],
    );

    return Padding(
      padding: effectivePadding,
      child: actions.isEmpty
          ? heading
          // The actions beside the title while it keeps its room, beneath
          // it â€” wrapping as needed â€” when a narrow window, a long
          // translation or a large text size wouldn't leave it any.
          : BesideOrBelow(
              minBodyWidth: 220,
              // Top-aligned: the actions line up with the window buttons.
              alignTop: true,
              body: heading,
              trailing: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ),
    );
  }
}

/// A rounded, flat panel â€” the desktop's one card surface.
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
