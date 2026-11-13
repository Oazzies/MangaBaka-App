part of 'desktop_dropdown.dart';

class _DesktopDropdownOverlay<T> extends StatefulWidget {
  final LayerLink layerLink;
  final Size targetSize;
  final Rect targetRect;
  final bool openUpward;
  final List<DesktopDropdownItem<T>> items;
  final T? selected;
  final Color backgroundColor;
  final double minWidth;
  final bool badgeMenu;
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
    this.badgeMenu = false,
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
    final menuRadius = BorderRadius.circular(widget.badgeMenu ? 22 : 14);
    // Wide enough for the longest option, so labels are not ellipsised while
    // the screen has room.
    final screenWidth = MediaQuery.sizeOf(context).width;
    var widest = 0.0;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: AppTypography.sans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final extras =
          (widget.badgeMenu
              ? 46.0
              : (item.icon != null || item.leading != null ? 27.0 : 0)) +
          (item.trailing != null ? 28.0 : 26.0);
      widest = math.max(widest, painter.width + extras);
      painter.dispose();
    }
    final menuWidth = math
        .max(math.max(widget.targetSize.width, widget.minWidth), widest + 40)
        .clamp(0.0, screenWidth - 24);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxMenuHeight = math
        .max(
          160.0,
          widget.openUpward
              ? widget.targetRect.top - 4 - 16
              : screenHeight - widget.targetRect.bottom - 4 - 16,
        )
        .toDouble();
    final menuLeft = math.min(
      widget.targetRect.left,
      screenWidth - menuWidth - 12,
    );

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
          left: math.max(12.0, menuLeft),
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
                  // Tall enough to show every option when the window has the
                  // room, so no scroll bar is needed.
                  constraints: BoxConstraints(maxHeight: maxMenuHeight),
                  padding: EdgeInsets.all(widget.badgeMenu ? 8 : 6),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: menuRadius,
                    // No drop shadow: SizeTransition clips to a rectangle,
                    // which turned the shadow into a dim box with square
                    // edges around the rounded menu.
                    border: Border.all(color: context.colors.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      widget.badgeMenu ? 16 : 10,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < widget.items.length; i++)
                            _DropdownRow<T>(
                              item: widget.items[i],
                              badge: widget.badgeMenu,
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

/// Opens the app's dropdown menu under [anchor] (a rect in global
/// coordinates) for a button that is not itself a [DesktopDropdown], with the
/// menu's right edge on the anchor's. The same light overlay the dropdowns
/// use, so it opens as quickly as they do.
void showDropdownMenuAt<T>(
  BuildContext context, {
  required Rect anchor,
  required List<DesktopDropdownItem<T>> items,
  required ValueChanged<T> onSelected,
  double width = 200,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final screen = MediaQuery.sizeOf(context);
  final left = (anchor.right - width).clamp(8.0, screen.width - width - 8);
  final target = Rect.fromLTWH(left, anchor.top, width, anchor.height);
  late final OverlayEntry entry;
  void close() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _DesktopDropdownOverlay<T>(
      layerLink: LayerLink(),
      targetSize: target.size,
      targetRect: target,
      openUpward: false,
      items: items,
      selected: null,
      backgroundColor: context.colors.surface,
      minWidth: width,
      onSelected: (value) {
        close();
        onSelected(value);
      },
      onDismiss: close,
    ),
  );
  overlay.insert(entry);
}
