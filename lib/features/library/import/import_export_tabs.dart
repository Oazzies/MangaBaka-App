import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_export_tiles.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';

class ImportExportCenteredMessage extends StatelessWidget {
  final String text;

  const ImportExportCenteredMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.sans(color: context.colors.textMuted),
      ),
    ),
  );
}

class ImportExportTabToggle extends StatelessWidget {
  final LocalizationService l10n;
  final ImportExportTab tab;
  final ValueChanged<ImportExportTab> onTabChanged;

  const ImportExportTabToggle({
    super.key,
    required this.l10n,
    required this.tab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: MbPill(
          label: l10n.translate('import_tab'),
          selected: tab == ImportExportTab.import,
          expand: true,
          onTap: () => onTabChanged(ImportExportTab.import),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: MbPill(
          label: l10n.translate('export_tab'),
          selected: tab == ImportExportTab.export,
          expand: true,
          onTap: () => onTabChanged(ImportExportTab.export),
        ),
      ),
    ],
  );
}

class ImportResultsView extends StatelessWidget {
  final LocalizationService l10n;
  final BulkImportController controller;
  final VoidCallback onAdd;

  const ImportResultsView({
    super.key,
    required this.l10n,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        if (c.isMatching)
          LinearProgressIndicator(
            value: c.progress,
            color: context.colors.accent,
            backgroundColor: context.colors.surfaceRaised,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n
                      .translate('import_summary')
                      .replaceAll('{selected}', '${c.selectedCount}')
                      .replaceAll('{total}', '${c.rows.length}'),
                  style: AppTypography.monoLabel(
                    color: context.colors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => c.selectAll(c.selectedCount == 0),
                child: Text(
                  l10n
                      .translate(c.selectedCount == 0 ? 'select_all' : 'clear')
                      .toUpperCase(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: c.rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => ImportRowTile(
              row: c.rows[i],
              l10n: l10n,
              onToggle: () => c.toggle(c.rows[i]),
              onChange: (index) => c.choose(c.rows[i], index),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: c.selectedCount == 0 || c.isAdding || c.isMatching
                    ? null
                    : onAdd,
                child: c.isAdding
                    ? const MbSpinner(size: 18, strokeWidth: 2)
                    : Text(
                        l10n
                            .translate('import_add_n')
                            .replaceAll('{count}', '${c.selectedCount}')
                            .toUpperCase(),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExportTabView extends StatelessWidget {
  final LocalizationService l10n;
  final List<LibraryEntry> entries;
  final ExportFormat exportFormat;
  final ValueChanged<ExportFormat> onExportFormatChanged;
  final Set<String> exportStates;
  final ValueChanged<String> onToggleExportState;
  final bool isExporting;
  final VoidCallback onExport;

  const ExportTabView({
    super.key,
    required this.l10n,
    required this.entries,
    required this.exportFormat,
    required this.onExportFormatChanged,
    required this.exportStates,
    required this.onToggleExportState,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = entries
        .where((e) => exportStates.contains(e.state))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Text(
          l10n.translate('export_subtitle'),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.translate('export_format').toUpperCase(),
          style: AppTypography.monoLabel(
            color: context.colors.textMuted,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 8),
        for (final f in ExportFormat.values) ...[
          ExportFormatTile(
            selected: f == exportFormat,
            title: l10n.translate(DesktopImportExportView.exportFormatKey(f)),
            subtitle: l10n.translate(
              DesktopImportExportView.exportFormatHintKey(f),
            ),
            onTap: () => onExportFormatChanged(f),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.translate('export_scope').toUpperCase(),
          style: AppTypography.monoLabel(
            color: context.colors.textMuted,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in DesktopImportExportView.states)
              MbPill(
                label: l10n.translate(s),
                selected: exportStates.contains(s),
                onTap: () => onToggleExportState(s),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n
              .translate('export_count')
              .replaceAll('{count}', '${filtered.length}'),
          style: AppTypography.monoLabel(
            color: context.colors.textMuted,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: filtered.isEmpty || isExporting ? null : onExport,
          child: isExporting
              ? const MbSpinner(size: 18, strokeWidth: 2)
              : Text(l10n.translate('export_action').toUpperCase()),
        ),
      ],
    );
  }
}
