part of 'desktop_import_export_view.dart';

extension _DesktopExportReview on DesktopImportExportView {
  List<Widget> _reviewActions(BuildContext context, LocalizationService l10n) {
    final c = controller;
    final canAdd = c.selectedCount > 0 && !c.isAdding && !c.isMatching;
    return [
      DesktopPillButton(
        label: l10n.translate(c.selectedCount == 0 ? 'select_all' : 'clear'),
        icon: c.selectedCount == 0
            ? Icons.select_all_rounded
            : Icons.deselect_rounded,
        onPressed: () => c.selectAll(c.selectedCount == 0),
      ),
      DesktopPillButton(
        label: l10n
            .translate('import_add_n')
            .replaceAll('{count}', '${c.selectedCount}'),
        icon: Icons.playlist_add_check_rounded,
        primary: true,
        onPressed: canAdd ? onAdd : null,
        trailing: c.isAdding
            ? MbSpinner(
                size: 14,
                strokeWidth: 2,
                color: context.colors.onAccent,
              )
            : null,
      ),
    ];
  }

  Widget _review(BuildContext context, LocalizationService l10n) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.isMatching)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesktopTokens.pagePadding,
              0,
              DesktopTokens.pagePadding,
              12,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: c.progress,
                minHeight: 4,
                color: context.colors.accent,
                backgroundColor: context.colors.surfaceRaised,
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              DesktopTokens.pagePadding,
              0,
              DesktopTokens.pagePadding,
              DesktopTokens.pagePadding,
            ),
            itemCount: c.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) => _ReviewRow(
              row: c.rows[i],
              l10n: l10n,
              onToggle: () => c.toggle(c.rows[i]),
              onChange: (index) => c.choose(c.rows[i], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _export(BuildContext context, LocalizationService l10n) {
    final filtered = libraryEntries
        .where((e) => exportStates.contains(e.state))
        .toList();
    final preview = filtered.isEmpty
        ? ''
        : ExportService.build(filtered, exportFormat);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        DesktopTokens.pagePadding,
        DesktopTokens.pagePadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DesktopCard(
              showBorder: false,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesktopSectionTitle(
                    title: l10n.translate('export_preview'),
                    fontSize: 13,
                    padding: const EdgeInsets.only(bottom: 10),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                l10n.translate('export_nothing_to_export'),
                                style: AppTypography.sans(
                                  color: context.colors.textMuted,
                                ),
                              ),
                            )
                          : Scrollbar(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  preview,
                                  style: AppTypography.sans(
                                    color: context.colors.text,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n
                        .translate('export_count')
                        .replaceAll('{count}', '${filtered.length}'),
                    style: AppTypography.monoLabel(
                      color: context.colors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(width: 320, child: _exportOptions(context, l10n, filtered)),
        ],
      ),
    );
  }

  Widget _exportOptions(
    BuildContext context,
    LocalizationService l10n,
    List<LibraryEntry> filtered,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _optionLabel(context, l10n.translate('export_format')),
              for (final f in ExportFormat.values) ...[
                _formatOption(context, l10n, f),
                if (f != ExportFormat.values.last) const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
              _optionLabel(context, l10n.translate('export_scope')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in DesktopImportExportView.states)
                    _scopeChip(context, l10n, s),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _wideButton(
          context,
          label: l10n.translate('export_action'),
          icon: Icons.ios_share_rounded,
          onPressed: filtered.isEmpty || isExporting ? null : onExport,
          trailing: isExporting
              ? MbSpinner(
                  size: 14,
                  strokeWidth: 2,
                  color: context.colors.onAccent,
                )
              : null,
        ),
      ],
    );
  }

  Widget _formatOption(
    BuildContext context,
    LocalizationService l10n,
    ExportFormat f,
  ) {
    final selected = f == exportFormat;
    return DesktopHoverSurface(
      onTap: () => onExportFormatChanged(f),
      selected: selected,
      selectedColor: context.colors.surfaceRaised,
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? context.colors.accent : context.colors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate(DesktopImportExportView.exportFormatKey(f)),
                  style: AppTypography.sans(
                    color: context.colors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.translate(DesktopImportExportView.exportFormatHintKey(f)),
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeChip(BuildContext context, LocalizationService l10n, String s) {
    final selected = exportStates.contains(s);
    return DesktopHoverSurface(
      onTap: () => onToggleExportState(s),
      selected: selected,
      selectedColor: context.colors.forState(s).withValues(alpha: 0.18),
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stateDot(context, s),
          const SizedBox(width: 8),
          Text(
            l10n.translate(s).toUpperCase(),
            style: AppTypography.display(
              color: selected ? context.colors.text : context.colors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
