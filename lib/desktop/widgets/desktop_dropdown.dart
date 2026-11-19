import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_dropdown_overlay_part.dart';
part 'desktop_dropdown_row_part.dart';

class DesktopDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;

  const DesktopDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
  });
}

class DesktopDropdown<T> extends StatefulWidget {
  final String? label;
  final String valueLabel;
  final IconData? icon;
  final Widget? leading;
  final List<DesktopDropdownItem<T>> items;
  final T? selected;
  final ValueChanged<T> onSelected;

  final Color? backgroundColor;

  final Color? foregroundColor;

  final Color? menuBackgroundColor;

  final BoxBorder? border;

  final double? width;

  final double minWidth;

  final EdgeInsetsGeometry padding;
  final double radius;

  final bool badgeMenu;

  const DesktopDropdown({
    super.key,
    this.label,
    required this.valueLabel,
    this.icon,
    this.leading,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.backgroundColor,
    this.menuBackgroundColor,
    this.foregroundColor,
    this.border,
    this.width,
    this.minWidth = 160,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.radius = AppConstants.pillRadius,
    this.badgeMenu = false,
  });

  @override
  State<DesktopDropdown<T>> createState() => _DesktopDropdownState<T>();
}

class _DesktopDropdownState<T> extends State<DesktopDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isHovered = false;

  @override
  void dispose() {
    _closeMenu(notify: false);
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isOpen) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final targetSize = renderBox.size;
    final targetRect = renderBox.localToGlobal(Offset.zero) & targetSize;
    final screenSize = MediaQuery.sizeOf(context);

    final spaceBelow = screenSize.height - targetRect.bottom;
    final spaceAbove = targetRect.top;
    final openUpward = spaceBelow < 220 && spaceAbove > spaceBelow;

    setState(() => _isOpen = true);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _DesktopDropdownOverlay<T>(
        layerLink: _layerLink,
        targetSize: targetSize,
        targetRect: targetRect,
        openUpward: openUpward,
        items: widget.items,
        selected: widget.selected,
        backgroundColor: widget.menuBackgroundColor ?? context.colors.surface,
        minWidth: widget.minWidth,
        badgeMenu: widget.badgeMenu,
        onSelected: (val) {
          _closeMenu();
          widget.onSelected(val);
        },
        onDismiss: _closeMenu,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _closeMenu({bool notify = true}) {
    if (!_isOpen && _overlayEntry == null) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? context.colors.surfaceRaised;
    final fg = widget.foregroundColor ?? context.colors.text;
    final hoverBg =
        Color.lerp(bg, context.colors.border, 0.45) ?? context.colors.border;

    final displayText = (widget.label != null && widget.label!.isNotEmpty)
        ? '${widget.label} · ${widget.valueLabel}'
        : widget.valueLabel;

    Widget content = CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleMenu,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isOpen
                  ? (widget.backgroundColor != null
                        ? bg
                        : context.colors.border)
                  : (_isHovered ? hoverBg : bg),
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
            ),
            child: Row(
              mainAxisSize: widget.width != null
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: 17, color: fg),
                  const SizedBox(width: 8),
                ],
                if (widget.width != null)
                  Expanded(
                    child: Text(
                      displayText.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(color: fg, fontSize: 12.5),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      displayText.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(color: fg, fontSize: 12.5),
                    ),
                  ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: content);
    }

    return content;
  }
}
