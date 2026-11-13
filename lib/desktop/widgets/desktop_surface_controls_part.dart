part of 'desktop_surfaces.dart';

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
    final bar = Container(
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

    // The segments' width depends on their labels — translated, sometimes
    // data (news sources) — so no breakpoint fits every language. When they
    // don't fit, the same choice becomes a dropdown instead of overflowing.
    // Icon-only bars are narrow and have no labels to list; they stay.
    if (segments.any((s) => s.$2 == null)) return bar;
    final selected = segments.where((s) => s.$1 == value).firstOrNull;
    return FitOrElse(
      fallback: DesktopMenuButton<T>(
        valueLabel: (selected?.$2 ?? segments.first.$2!).toUpperCase(),
        items: [for (final (segment, label, _) in segments) (segment, label!)],
        selected: value,
        onSelected: onChanged,
      ),
      child: bar,
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
    return BesideOrBelow(
      leading: SizedBox(
        width: 24,
        child: Icon(icon, color: context.colors.textMuted, size: 20),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
      // Beside the text while it keeps a readable width, beneath it when a
      // wide control (a long translated dropdown value) wouldn't leave one.
      trailing: control,
    );
  }
}
