part of 'desktop_import_export_view.dart';

class _SourceCard extends StatelessWidget {
  final ImportSource source;

  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopHoverSurface(
      onTap: source.onTap,
      idleColor: context.colors.surfaceRaised,
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      tooltip: l10n.translate(source.hintKey),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImportSourceIcon(source: source, size: 18),
          const SizedBox(width: 8),
          Text(
            l10n.translate(source.labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final ImportRow row;
  final LocalizationService l10n;
  final VoidCallback onToggle;
  final ValueChanged<int> onChange;

  const _ReviewRow({
    required this.row,
    required this.l10n,
    required this.onToggle,
    required this.onChange,
  });

  String get _status => switch (row.status) {
    ImportRowStatus.pending => l10n.translate('import_matching'),
    ImportRowStatus.matched => '',
    ImportRowStatus.notFound => l10n.translate('import_no_match'),
    ImportRowStatus.inLibrary => l10n.translate('import_in_library'),
    ImportRowStatus.failed => l10n.translate('import_check_failed'),
  };

  @override
  Widget build(BuildContext context) {
    final match = row.match;
    final muted = !row.canSelect;
    final title = match?.getDisplayTitle(
      SettingsManager().defaultTitleLanguage,
    );

    return DesktopHoverSurface(
      onTap: row.canSelect ? onToggle : null,
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: row.canSelect
                ? Checkbox(value: row.selected, onChanged: (_) => onToggle())
                : null,
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: match != null && match.coverUrl.isNotEmpty
                  ? WidgetUtils.networkImage(
                      url: match.coverUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                    )
                  : Container(color: context.colors.surfaceRaised),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? row.query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: muted
                        ? context.colors.textMuted
                        : context.colors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                if (match != null && title != row.query)
                  Text(
                    row.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (row.sourceState != null) ...[
            const SizedBox(width: 12),
            _chip(
              l10n.translate(row.sourceState!),
              context.colors.forState(row.sourceState!),
            ),
          ],
          if (_status.isNotEmpty) ...[
            const SizedBox(width: 12),
            _chip(
              _status,
              row.status == ImportRowStatus.inLibrary
                  ? context.colors.accent
                  : context.colors.textMuted,
            ),
          ],
          if (row.candidates.length > 1) ...[
            const SizedBox(width: 12),
            DesktopDropdown<int>(
              valueLabel: l10n.translate('import_change_match'),
              icon: Icons.swap_horiz_rounded,
              minWidth: 260,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              items: [
                for (var i = 0; i < row.candidates.length; i++)
                  DesktopDropdownItem(
                    value: i,
                    label: row.candidates[i].getDisplayTitle(
                      SettingsManager().defaultTitleLanguage,
                    ),
                  ),
              ],
              selected: row.chosen,
              onSelected: onChange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
    ),
    child: Text(
      label.toUpperCase(),
      style: AppTypography.monoLabel(color: color, fontSize: 10.5),
    ),
  );
}
