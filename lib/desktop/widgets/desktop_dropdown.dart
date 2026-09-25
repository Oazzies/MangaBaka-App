import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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

/// A desktop dropdown styled around the app's pill-button design system.
/// The button itself is a clean pill button (with hover, icon, display text, and chevron).
/// When clicked, a dropdown menu matching the app styling opens below it.
class DesktopDropdown<T> extends StatefulWidget {
  /// Optional label prefix. When omitted or empty, only [valueLabel] is shown.
  final String? label;
  final String valueLabel;
  final IconData? icon;
  final Widget? leading;
  final List<DesktopDropdownItem<T>> items;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Custom background color for the button. Defaults to [context.colors.surfaceRaised].
  final Color? backgroundColor;

  /// Custom text & icon color for the button. Defaults to [context.colors.text].
  final Color? foregroundColor;

  /// Custom background color for the dropdown menu. Defaults to [context.colors.surface].
  final Color? menuBackgroundColor;

  /// Optional border for the button itself. Defaults to null.
  final BoxBorder? border;

  /// Exact width for the dropdown button.
  final double? width;

  /// Minimum width for the dropdown menu. Defaults to 160.
  final double minWidth;

  final EdgeInsetsGeometry padding;
  final double radius;

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

    // Determine whether to open downward or flip upward if space is tight
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
                  // Its natural width where there's room; ellipsised rather
                  // than overflowing when the button is squeezed.
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

class _DesktopDropdownOverlay<T> extends StatefulWidget {
  final LayerLink layerLink;
  final Size targetSize;
  final Rect targetRect;
  final bool openUpward;
  final List<DesktopDropdownItem<T>> items;
  final T? selected;
  final Color backgroundColor;
  final double minWidth;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  const _DesktopDropdownOverlay({
    required this.layerLink,
    required this.targetSize,
    required this.targetRect,
    required this.openUpward,
    required this.items,
    required this.selected,
    required this.backgroundColor,
    required this.minWidth,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  State<_DesktopDropdownOverlay<T>> createState() =>
      _DesktopDropdownOverlayState<T>();
}

class _DesktopDropdownOverlayState<T> extends State<_DesktopDropdownOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuRadius = BorderRadius.circular(14);
    final menuWidth = math.max(widget.targetSize.width, widget.minWidth);

    return Stack(
      children: [
        // Transparent barrier to capture clicks outside and close
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        // Dropdown menu positioned just below/above the button with matching styling
        Positioned(
          left: widget.targetRect.left,
          top: widget.openUpward ? null : widget.targetRect.bottom + 4,
          bottom: widget.openUpward
              ? (MediaQuery.sizeOf(context).height - widget.targetRect.top + 4)
              : null,
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: SizeTransition(
                sizeFactor: _expandAnimation,
                alignment: widget.openUpward
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: Container(
                  width: menuWidth,
                  constraints: const BoxConstraints(maxHeight: 320),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: menuRadius,
                    border: Border.all(color: context.colors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.shadowAt(0.5),
                        blurRadius: 18,
                        offset: Offset(0, widget.openUpward ? -8 : 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < widget.items.length; i++)
                            _DropdownRow<T>(
                              item: widget.items[i],
                              isSelected:
                                  widget.items[i].value == widget.selected,
                              onTap: () =>
                                  widget.onSelected(widget.items[i].value),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownRow<T> extends StatefulWidget {
  final DesktopDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DropdownRow<T>> createState() => _DropdownRowState<T>();
}

class _DropdownRowState<T> extends State<_DropdownRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final item = widget.item;
    final activeColor = item.iconColor ?? context.colors.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.14)
                : (_hovered
                      ? context.colors.surfaceRaised
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (item.leading != null) ...[
                item.leading!,
                const SizedBox(width: 10),
              ] else if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 17,
                  color:
                      item.iconColor ??
                      (isSelected ? activeColor : context.colors.textMuted),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: isSelected ? activeColor : context.colors.text,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (item.trailing != null) ...[
                const SizedBox(width: 8),
                item.trailing!,
              ] else if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 16, color: activeColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
