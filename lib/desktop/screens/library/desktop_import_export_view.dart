import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The hub's two halves: bringing a list in, or writing the library out.
enum ImportExportTab { import, export }

/// One tracker or file the importer can read from, shown as its own card in
/// the source picker rather than folded into a generic "open a file" button.
class ImportSource {
  final IconData icon;
  final String labelKey;
  final String hintKey;
  final VoidCallback onTap;

  const ImportSource({
    required this.icon,
    required this.labelKey,
    required this.hintKey,
    required this.onTap,
  });
}

/// The import/export hub on desktop.
///
/// The phone's version is one narrow column: a tab toggle over a source grid
/// or a paste box over a state dropdown over a button. On a wide window that
/// is a lot of empty space and stock Material controls, so here the source
/// sits beside its options, and everything is built from the desktop's own
/// controls.
///
/// Stateless on purpose: the screen that owns the controller and the text also
/// serves the phone, so it keeps the state and hands this view what to show.
class DesktopImportExportView extends StatelessWidget {
  final ImportExportTab tab;
  final ValueChanged<ImportExportTab> onTabChanged;

  final BulkImportController controller;
  final TextEditingController text;
  final List<ImportSource> sources;

  final ImportFormat format;
  final ValueChanged<ImportFormat> onFormatChanged;
  final bool useStates;
  final ValueChanged<bool> onUseStatesChanged;

  /// The source the text was loaded from, shown beside the source grid.
  final String? sourceLabel;

  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onMatch;
  final VoidCallback onAdd;

  final List<LibraryEntry> libraryEntries;
  final Set<String> exportStates;
  final ValueChanged<String> onToggleExportState;
  final ExportFormat exportFormat;
  final ValueChanged<ExportFormat> onExportFormatChanged;
  final bool isExporting;
  final VoidCallback onExport;

  static const List<String> states = [
    'plan_to_read',
    'reading',
    'completed',
    'paused',
    'dropped',
    'rereading',
    'considering',
  ];

  const DesktopImportExportView({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.controller,
    required this.text,
    required this.sources,
    required this.format,
    required this.onFormatChanged,
    required this.useStates,
    required this.onUseStatesChanged,
    required this.sourceLabel,
    required this.onBack,
    required this.onClear,
    required this.onMatch,
    required this.onAdd,
    required this.libraryEntries,
    required this.exportStates,
    required this.onToggleExportState,
    required this.exportFormat,
    required this.onExportFormatChanged,
    required this.isExporting,
    required this.onExport,
  });

  static String formatKey(ImportFormat format) => switch (format) {
    ImportFormat.auto => 'import_format_auto',
    ImportFormat.plain => 'import_format_plain',
    ImportFormat.csv => 'import_format_csv',
    ImportFormat.json => 'import_format_json',
    ImportFormat.myAnimeList => 'import_format_mal',
    ImportFormat.mangaUpdates => 'import_format_mu',
    ImportFormat.mangaBaka => 'import_format_mb',
  };

  static String exportFormatKey(ExportFormat format) => switch (format) {
    ExportFormat.mangaBaka => 'export_format_mb',
    ExportFormat.csv => 'export_format_csv',
    ExportFormat.plain => 'export_format_plain',
  };

  static String exportFormatHintKey(ExportFormat format) => switch (format) {
    ExportFormat.mangaBaka => 'export_format_mb_hint',
    ExportFormat.csv => 'export_format_csv_hint',
    ExportFormat.plain => 'export_format_plain_hint',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final review = controller.hasRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPageHeader(
          title: l10n.translate('import_export_title'),
          subtitle: review
              ? l10n
                    .translate('import_summary')
                    .replaceAll('{selected}', '${controller.selectedCount}')
                    .replaceAll('{total}', '${controller.rows.length}')
              : l10n.translate(
                  tab == ImportExportTab.import
                      ? 'import_list_subtitle'
                      : 'export_subtitle',
                ),
          leading: DesktopIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.translate('back'),
            onPressed: onBack,
            filled: true,
          ),
          actions: review
              ? _reviewActions(context, l10n)
              : [
                  DesktopSegmented<ImportExportTab>(
                    value: tab,
                    onChanged: onTabChanged,
                    segments: [
                      (
                        ImportExportTab.import,
                        l10n.translate('import_tab'),
                        Icons.file_download_outlined,
                      ),
                      (
                        ImportExportTab.export,
                        l10n.translate('export_tab'),
                        Icons.file_upload_outlined,
                      ),
                    ],
                  ),
                ],
        ),
        Expanded(
          child: review
              ? _review(context, l10n)
              : tab == ImportExportTab.import
              ? _import(context, l10n)
              : _export(context, l10n),
        ),
      ],
    );
  }

  // ─── Import ──────────────────────────────────────────────────────────────

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
                .replaceAll('{format}', l10n.translate(formatKey(detected))),
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
                  // A fixed-height scrolling strip rather than a wrapping
                  // grid: this card also holds the paste box beneath it, and
                  // a grid tall enough for eight two-line cards would push
                  // that box past the window's bottom at the 700px minimum
                  // height this screen supports.
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sources.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _SourceCard(source: sources[i]),
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
                        border: _fieldBorder,
                        enabledBorder: _fieldBorder,
                        focusedBorder: _fieldBorder,
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

  static final OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

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
                valueLabel: l10n.translate(formatKey(format)),
                icon: Icons.description_outlined,
                width: double.infinity,
                items: [
                  for (final f in ImportFormat.values)
                    DesktopDropdownItem(
                      value: f,
                      label: l10n.translate(formatKey(f)),
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
        for (final s in states)
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

  // ─── Review ──────────────────────────────────────────────────────────────

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
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.onAccent,
                ),
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

  // ─── Export ──────────────────────────────────────────────────────────────

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
                  for (final s in states) _scopeChip(context, l10n, s),
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
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onAccent,
                  ),
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
                  l10n.translate(exportFormatKey(f)),
                  style: AppTypography.sans(
                    color: context.colors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.translate(exportFormatHintKey(f)),
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

/// A source pill in the fixed-height scrolling strip: its hint (the thing a
/// two-line card would have shown beneath the label) lives in the tooltip
/// instead, so the strip never needs more than one row of height.
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
          Icon(source.icon, size: 16, color: context.colors.accent),
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
