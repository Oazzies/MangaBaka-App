part of 'desktop_dropdown.dart';

class _DropdownRow<T> extends StatefulWidget {
  final DesktopDropdownItem<T> item;
  final bool badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownRow({
    required this.item,
    this.badge = false,
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

    if (widget.badge) {
      final fg = context.colors.on(activeColor);
      final rowFill = isSelected
          ? activeColor
          : (_hovered
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(
                color: rowFill,
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? fg.withValues(alpha: 0.18)
                          : activeColor.withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: isSelected ? fg : activeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(
                        color: isSelected ? fg : context.colors.text,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_rounded, size: 18, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

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
