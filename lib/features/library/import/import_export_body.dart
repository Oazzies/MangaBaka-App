import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_export_input_tab.dart';
import 'package:mangabaka_app/features/library/import/import_export_tabs.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';

class ImportExportScaffold extends StatelessWidget {
  final ImportExportTab tab;
  final ValueChanged<ImportExportTab> onTabChanged;
  final BulkImportController controller;
  final LibraryService library;
  final TextEditingController textController;
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
  final Set<String> exportStates;
  final ValueChanged<String> onToggleExportState;
  final ExportFormat exportFormat;
  final ValueChanged<ExportFormat> onExportFormatChanged;
  final bool isExporting;
  final ValueChanged<List<LibraryEntry>> onExport;

  const ImportExportScaffold({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.controller,
    required this.library,
    required this.textController,
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
    required this.exportStates,
    required this.onToggleExportState,
    required this.exportFormat,
    required this.onExportFormatChanged,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final isLoggedIn = getIt<ProfileAuthService>().isLoggedIn;

    if (DesktopLayout.isActive(context)) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: !isLoggedIn
            ? ImportExportCenteredMessage(
                text: l10n.translate('import_login_required'),
              )
            : StreamBuilder<List<LibraryEntry>>(
                stream: library.watchEntriesFromDb(),
                initialData: const [],
                builder: (context, snapshot) {
                  final entries = snapshot.data ?? const [];
                  return ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => DesktopImportExportView(
                      tab: tab,
                      onTabChanged: onTabChanged,
                      controller: controller,
                      text: textController,
                      sources: sources,
                      format: format,
                      onFormatChanged: onFormatChanged,
                      useStates: useStates,
                      onUseStatesChanged: onUseStatesChanged,
                      sourceLabel: sourceLabel,
                      onBack: onBack,
                      onClear: onClear,
                      onMatch: onMatch,
                      onAdd: onAdd,
                      libraryEntries: entries,
                      exportStates: exportStates,
                      onToggleExportState: onToggleExportState,
                      exportFormat: exportFormat,
                      onExportFormatChanged: onExportFormatChanged,
                      isExporting: isExporting,
                      onExport: () => onExport(entries),
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: l10n.translate('import_export_title')),
      body: WidgetUtils.responsiveConstraint(
        maxWidth: 760,
        !isLoggedIn
            ? ImportExportCenteredMessage(
                text: l10n.translate('import_login_required'),
              )
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => controller.hasRows
                    ? ImportResultsView(
                        l10n: l10n,
                        controller: controller,
                        onAdd: onAdd,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: ImportExportTabToggle(
                              l10n: l10n,
                              tab: tab,
                              onTabChanged: onTabChanged,
                            ),
                          ),
                          Expanded(
                            child: tab == ImportExportTab.import
                                ? ImportInputTab(
                                    l10n: l10n,
                                    textController: textController,
                                    sources: sources,
                                    format: format,
                                    onFormatChanged: onFormatChanged,
                                    useStates: useStates,
                                    onUseStatesChanged: onUseStatesChanged,
                                    sourceLabel: sourceLabel,
                                    onClear: onClear,
                                    onMatch: onMatch,
                                    controller: controller,
                                  )
                                : StreamBuilder<List<LibraryEntry>>(
                                    stream: library.watchEntriesFromDb(),
                                    initialData: const [],
                                    builder: (context, snapshot) {
                                      final entries =
                                          snapshot.data ?? const [];
                                      return ExportTabView(
                                        l10n: l10n,
                                        entries: entries,
                                        exportFormat: exportFormat,
                                        onExportFormatChanged:
                                            onExportFormatChanged,
                                        exportStates: exportStates,
                                        onToggleExportState:
                                            onToggleExportState,
                                        isExporting: isExporting,
                                        onExport: () => onExport(entries),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
