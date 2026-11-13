import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_export_actions.dart';
import 'package:mangabaka_app/features/library/import/import_export_body.dart';
import 'package:mangabaka_app/features/library/import/import_export_dialogs.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Bring a list in from a tracker or file, or write the local library back
/// out.
///
/// Import: paste, match, prune, add — each line is matched against the
/// catalogue (strictly - see [SeriesMatchService]), the user reviews what
/// matched, and the chosen series go in with a single batch request.
/// Export: pick a scope and a format, then share or save the file.
class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  static void open(BuildContext context) => Navigator.of(
    context,
  ).push(AppTransitions.slideRight(const ImportExportScreen()));

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  late final SeriesMatchService _matcher = SeriesMatchService();
  late final LibraryService _library = getIt<LibraryService>();
  late final BulkImportController _controller;
  final TextEditingController _text = TextEditingController();

  ImportExportTab _tab = ImportExportTab.import;

  ImportFormat _format = ImportFormat.auto;
  bool _useStates = true;

  /// The source the text was loaded from, if it wasn't just pasted.
  String? _sourceLabel;

  ExportFormat _exportFormat = ExportFormat.mangaBaka;
  final Set<String> _exportStates = {...DesktopImportExportView.states};
  bool _exporting = false;

  /// Extensions the generic file picker offers, one per [ImportFormat] that
  /// reads a file.
  static const List<String> _fileExtensions = [
    'txt',
    'csv',
    'json',
    'xml',
    'gz',
    'tachibk',
    'proto',
  ];

  @override
  void initState() {
    super.initState();
    _controller = BulkImportController(
      match: _matcher.match,
      isInLibrary: (id) async =>
          await _library.database.libraryEntriesDao.getEntryBySeriesId(id) !=
          null,
      addBatch: _library.createLibraryEntriesBatch,
      state: SettingsManager().addLibraryDefaultTab,
    );
    // The title count and detected format follow the text as it is edited.
    _text.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _text.removeListener(_onTextChanged);
    _controller.dispose();
    _matcher.dispose();
    _text.dispose();
    super.dispose();
  }

  void _match() => _controller.start(
    _text.text,
    format: _format,
    useStates: _useStates,
    fileName: _sourceLabel,
  );

  // ─── Import sources ──────────────────────────────────────────────────────

  List<ImportSource> _sources(LocalizationService l10n) => buildImportSources(
    onAniList: _fromAniList,
    onKitsu: _fromKitsu,
    onOpenFileAs: _openFileAs,
    onPaste: _paste,
    onOpenFile: _openFile,
  );

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.trim().isEmpty || !mounted) return;
    setState(() => _sourceLabel = null);
    _text.text = pasted;
  }

  Future<void> _openFile() => _pickFile(allowedExtensions: _fileExtensions);

  /// Opens a file for a named tracker source, prefixing [_sourceLabel] with
  /// its name so the picker step (and the review step after it) reads
  /// "Manga-Updates · export.json" rather than a bare filename.
  Future<void> _openFileAs({
    required List<String> extensions,
    required String labelKey,
  }) => _pickFile(allowedExtensions: extensions, labelPrefixKey: labelKey);

  Future<void> _pickFile({
    required List<String> allowedExtensions,
    String? labelPrefixKey,
  }) async {
    try {
      final result = await pickAndReadImportFile(
        allowedExtensions: allowedExtensions,
        labelPrefixKey: labelPrefixKey,
      );
      if (result == null || !mounted) return;
      _applySourceText(result.label, result.contents);
    } on ImportSourceException catch (e) {
      _sourceFailed(e);
    } catch (e, st) {
      LoggingService.logger.warning('Failed to open import file', e, st);
      _sourceFailed(const ImportSourceException('import_file_failed'));
    }
  }

  void _applySourceText(String label, String contents) {
    setState(() {
      _sourceLabel = label;
      _format = ImportFormat.auto;
    });
    _text.text = contents;
  }

  void _sourceFailed(ImportSourceException e) {
    if (!mounted) return;
    AppSnackBar.show(
      context,
      LocalizationService().translate(e.key),
      isError: true,
    );
  }

  /// Loads a public AniList manga list by username into the text box.
  Future<void> _fromAniList() =>
      _runTrackerFetch(() => fetchAniListImportList(context));

  /// Loads a public Kitsu manga library by username into the text box.
  Future<void> _fromKitsu() =>
      _runTrackerFetch(() => fetchKitsuImportList(context));

  Future<void> _runTrackerFetch(
    Future<({String label, String contents})?> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      if (result == null || !mounted) return;
      _applySourceText(result.label, result.contents);
    } on ImportSourceException catch (e) {
      _sourceFailed(e);
    }
  }

  void _clearText() {
    setState(() => _sourceLabel = null);
    _text.clear();
  }

  /// Back from the review step returns to the paste step; back from the
  /// paste step leaves the screen.
  void _back() {
    if (_controller.hasRows) {
      _controller.reset();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _add() async {
    final l10n = LocalizationService();
    try {
      final count = await _controller.addSelected();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        l10n.translate('import_added').replaceAll('{count}', '$count'),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      LoggingService.logger.warning('Failed to add imported entries', e, st);
      if (!mounted) return;
      AppSnackBar.show(context, l10n.translate('failed_to_add'), isError: true);
    }
  }

  // ─── Export ──────────────────────────────────────────────────────────────

  void _toggleExportState(String state) {
    setState(() {
      if (_exportStates.contains(state)) {
        if (_exportStates.length > 1) _exportStates.remove(state);
      } else {
        _exportStates.add(state);
      }
    });
  }

  Future<void> _doExport(List<LibraryEntry> entries) async {
    final l10n = LocalizationService();
    final filtered = entries
        .where((e) => _exportStates.contains(e.state))
        .toList();
    if (filtered.isEmpty || _exporting) return;

    setState(() => _exporting = true);
    try {
      final count = await exportLibraryToShareSheet(
        filteredEntries: filtered,
        format: _exportFormat,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        l10n.translate('export_done').replaceAll('{count}', '$count'),
      );
    } catch (e, st) {
      LoggingService.logger.warning('Failed to export library', e, st);
      if (!mounted) return;
      AppSnackBar.show(context, l10n.translate('export_failed'), isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ImportExportScaffold(
      tab: _tab,
      onTabChanged: (t) => setState(() => _tab = t),
      controller: _controller,
      library: _library,
      textController: _text,
      sources: _sources(l10n),
      format: _format,
      onFormatChanged: (f) => setState(() => _format = f),
      useStates: _useStates,
      onUseStatesChanged: (v) => setState(() => _useStates = v),
      sourceLabel: _sourceLabel,
      onBack: _back,
      onClear: _clearText,
      onMatch: _match,
      onAdd: _add,
      exportStates: _exportStates,
      onToggleExportState: _toggleExportState,
      exportFormat: _exportFormat,
      onExportFormatChanged: (f) => setState(() => _exportFormat = f),
      isExporting: _exporting,
      onExport: _doExport,
    );
  }
}
