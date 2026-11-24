part of 'desktop_lists_page.dart';

abstract final class _Col {
  static const double check = 44;
  static const double series = 96;
  static const double visibility = 120;
  static const double created = 130;
  static const double menu = 44;
}

class _TableHeader extends StatelessWidget {
  final bool allSelected;
  final VoidCallback onToggleAll;

  const _TableHeader({required this.allSelected, required this.onToggleAll});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    TextStyle style() =>
        AppTypography.displayLabel(color: c.textMuted, fontSize: 12);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesktopTokens.pagePadding - 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Col.check,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Checkbox(
                value: allSelected,
                onChanged: (_) => onToggleAll(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.translate('lists_col_name').toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _Col.series,
            child: Text(
              l10n.translate('lists_col_series').toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _Col.visibility,
            child: Text(
              l10n.translate('lists_col_visibility').toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _Col.created,
            child: Text(
              l10n.translate('lists_col_created').toUpperCase(),
              style: style(),
            ),
          ),
          const SizedBox(width: _Col.menu),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final LibraryList list;
  final int count;
  final bool selected;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final ValueChanged<Rect?> onMenu;

  const _TableRow({
    super.key,
    required this.list,
    required this.count,
    required this.selected,
    required this.busy,
    required this.onToggle,
    required this.onOpen,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    final created = list.createdAt;
    final muted = AppTypography.sans(color: c.textMuted, fontSize: 13.5);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Builder(
        builder: (context) => DesktopHoverSurface(
          onTap: onOpen,
          onSecondaryTap: () => onMenu(globalRectOf(context)),
          selected: selected,
          selectedColor: c.surfaceRaised,
          hoverColor: c.surface,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: _Col.check,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: c.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: _Col.series,
                child: Text(NumberUtils.formatCount(count), style: muted),
              ),
              SizedBox(
                width: _Col.visibility,
                child: Row(
                  children: [
                    Icon(
                      list.isPrivate
                          ? Icons.lock_rounded
                          : Icons.public_rounded,
                      size: 15,
                      color: c.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.translate(
                          list.isPrivate ? 'lists_private' : 'lists_public',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: _Col.created,
                child: Text(
                  created == null
                      ? '–'
                      : AppDateUtils.formatFullDate(created.toIso8601String()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
              SizedBox(
                width: _Col.menu,
                height: 40,
                child: busy
                    ? const Center(child: MbSpinner(size: 16))
                    : Builder(
                        builder: (context) => DesktopIconButton(
                          icon: Icons.more_horiz_rounded,
                          size: 18,
                          tooltip: l10n.translate('more_options'),
                          onPressed: () => onMenu(globalRectOf(context)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
