part of 'desktop_import_export_view.dart';

final OutlineInputBorder _importFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide.none,
);

extension _DesktopImportSection on DesktopImportExportView {
  Widget _import(BuildContext context, LocalizationService l10n) {
    final detected = format == ImportFormat.auto
        ? ImportParser.detect(text.text, fileName: sourceLabel)
        : format;
    final titleCount = ImportParser.parse(
      text.text,
      format: format,
      useStates: useStates,
      fileName: sourceLabel,
    ).length;

    final summary = titleCount == 0
        ? l10n.translate('import_no_titles')
        : [
            l10n
                .translate('import_titles_found')
                .replaceAll('{count}', '$titleCount'),
            l10n
                .translate('import_detected')
                .replaceAll(
                  '{format}',
                  l10n.translate(DesktopImportExportView.formatKey(detected)),
                ),
          ].join(' · ');

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
                    title: l10n.translate('import_choose_source'),
                    fontSize: 13,
                    padding: const EdgeInsets.only(bottom: 10),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sources.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) =>
                          _SourceCard(source: sources[i]),
                    ),
                  ),
                  if (sourceLabel != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sourceLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(
                              color: context.colors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        DesktopPillButton(
                          label: l10n.translate('clear'),
                          icon: Icons.close_rounded,
                          onPressed: text.text.isEmpty ? null : onClear,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Expanded(
                    child: TextField(
                      controller: text,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.translate('import_paste_hint'),
                        filled: true,
                        fillColor: context.colors.surfaceRaised,
                        contentPadding: const EdgeInsets.all(18),
                        border: _importFieldBorder,
                        enabledBorder: _importFieldBorder,
                        focusedBorder: _importFieldBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary,
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
          SizedBox(
            width: 320,
            child: _importOptions(context, l10n, titleCount),
          ),
        ],
      ),
    );
  }

  Widget _importOptions(
    BuildContext context,
    LocalizationService l10n,
    int titleCount,
  ) {
    final canUseStates = ImportParser.carriesStates(
      format == ImportFormat.auto
          ? ImportParser.detect(text.text, fileName: sourceLabel)
          : format,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _optionLabel(context, l10n.translate('import_format')),
              DesktopDropdown<ImportFormat>(
                valueLabel: l10n.translate(
                  DesktopImportExportView.formatKey(format),
                ),
                icon: Icons.description_outlined,
                width: double.infinity,
                items: [
                  for (final f in ImportFormat.values)
                    DesktopDropdownItem(
                      value: f,
                      label: l10n.translate(
                        DesktopImportExportView.formatKey(f),
                      ),
                    ),
                ],
                selected: format,
                onSelected: onFormatChanged,
              ),
              const SizedBox(height: 18),
              _optionLabel(context, l10n.translate('import_add_as')),
              _stateDropdown(context, l10n),
              if (canUseStates) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('import_use_statuses'),
                            style: AppTypography.sans(
                              color: context.colors.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.translate('import_use_statuses_subtitle'),
                            style: AppTypography.sans(
                              color: context.colors.textMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(value: useStates, onChanged: onUseStatesChanged),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _wideButton(
          context,
          label: l10n.translate('import_match'),
          icon: Icons.manage_search_rounded,
          onPressed: titleCount == 0 ? null : onMatch,
        ),
      ],
    );
  }

  Widget _optionLabel(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      label.toUpperCase(),
      style: AppTypography.monoLabel(
        color: context.colors.textMuted,
        fontSize: 11.5,
      ),
    ),
  );

  Widget _stateDropdown(BuildContext context, LocalizationService l10n) {
    return DesktopDropdown<String>(
      valueLabel: l10n.translate(controller.state),
      icon: Icons.bookmark_border_rounded,
      width: double.infinity,
      items: [
        for (final s in DesktopImportExportView.states)
          DesktopDropdownItem(
            value: s,
            label: l10n.translate(s),
            leading: _stateDot(context, s),
          ),
      ],
      selected: controller.state,
      onSelected: controller.setTargetState,
    );
  }

  Widget _stateDot(BuildContext context, String state) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: context.colors.forState(state),
      shape: BoxShape.circle,
    ),
  );

  Widget _wideButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Widget? trailing,
  }) {
    final enabled = onPressed != null;
    final fg = context.colors.onAccent;
    return DesktopHoverSurface(
      onTap: onPressed,
      idleColor: enabled ? context.colors.accent : context.colors.surfaceRaised,
      hoverColor: enabled
          ? context.colors.hoverOf(context.colors.accent)
          : context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: enabled ? fg : context.colors.textMuted),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: AppTypography.display(
              color: enabled ? fg : context.colors.textMuted,
              fontSize: 13.5,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing],
        ],
      ),
    );
  }
}
