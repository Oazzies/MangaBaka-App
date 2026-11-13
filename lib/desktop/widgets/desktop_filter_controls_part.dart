part of 'desktop_filter_panel.dart';

class _Section extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    if (widget.trailing != null && _open) widget.trailing!,
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _open ? 0 : -0.25,
                      duration: AppMotion.fast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _open
                ? widget.child
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A compact include/exclude chip for pointer use.
class DesktopTriChip extends StatelessWidget {
  final String label;
  final TriState state;
  final ValueChanged<TriState> onChanged;

  const DesktopTriChip({
    super.key,
    required this.label,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData? icon) = switch (state) {
      TriState.include => (
        context.colors.accent,
        context.colors.onAccent,
        Icons.check_rounded,
      ),
      TriState.exclude => (
        context.colors.error,
        context.colors.on(context.colors.error),
        Icons.remove_rounded,
      ),
      TriState.off => (
        context.colors.surface,
        context.colors.text.withValues(alpha: 0.82),
        null,
      ),
    };

    return DesktopHoverSurface(
      onTap: () => onChanged(switch (state) {
        TriState.off => TriState.include,
        TriState.include => TriState.exclude,
        TriState.exclude => TriState.off,
      }),
      onSecondaryTap: () => onChanged(
        state == TriState.exclude ? TriState.off : TriState.exclude,
      ),
      tooltip: LocalizationService().translate('tri_chip_hint'),
      idleColor: bg,
      hoverColor: state == TriState.off
          ? context.colors.surfaceRaised
          : Color.lerp(bg, context.colors.text, 0.14),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 8, 6, 12, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.sans(
              color: fg,
              fontSize: 12.5,
              fontWeight: state == TriState.off
                  ? FontWeight.w500
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String name;
  final String? path;
  final TriState state;
  final ValueChanged<TriState> onChanged;

  const _TagRow({
    required this.name,
    required this.path,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final parents = (path ?? '').split('>').map((p) => p.trim()).toList();
    if (parents.isNotEmpty) parents.removeLast();
    final context_ = parents.where((p) => p.isNotEmpty).join(' › ');

    return DesktopHoverSurface(
      onTap: () => onChanged(
        state == TriState.include ? TriState.off : TriState.include,
      ),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: state == TriState.off
                        ? context.colors.text
                        : (state == TriState.include
                              ? context.colors.accent
                              : context.colors.error),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (context_.isNotEmpty)
                  Text(
                    context_,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          _MiniToggle(
            icon: Icons.add_rounded,
            active: state == TriState.include,
            color: context.colors.accent,
            onTap: () => onChanged(
              state == TriState.include ? TriState.off : TriState.include,
            ),
          ),
          _MiniToggle(
            icon: Icons.remove_rounded,
            active: state == TriState.exclude,
            color: context.colors.error,
            onTap: () => onChanged(
              state == TriState.exclude ? TriState.off : TriState.exclude,
            ),
          ),
        ],
      ),
    );
  }
}
