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
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

part 'desktop_import_section_part.dart';
part 'desktop_export_review_part.dart';
part 'desktop_import_export_cards_part.dart';

enum ImportExportTab { import, export }

class ImportSource {
  final IconData icon;

  final String? logoAsset;
  final String labelKey;
  final String hintKey;
  final VoidCallback onTap;

  const ImportSource({
    required this.icon,
    this.logoAsset,
    required this.labelKey,
    required this.hintKey,
    required this.onTap,
  });
}

class ImportSourceIcon extends StatelessWidget {
  final ImportSource source;
  final double size;

  const ImportSourceIcon({super.key, required this.source, required this.size});

  @override
  Widget build(BuildContext context) {
    final logo = source.logoAsset;
    if (logo == null) {
      return Icon(source.icon, size: size, color: context.colors.accent);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Stateless on purpose: the owning screen also serves the phone, so it keeps the state.
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
              : null,
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
                        Icons.file_download_rounded,
                      ),
                      (
                        ImportExportTab.export,
                        l10n.translate('export_tab'),
                        Icons.file_upload_rounded,
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
}
