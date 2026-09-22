import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_view.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Add many series to the library from a pasted list of titles.
///
/// Paste, match, prune, add: each line is matched against the catalogue
/// (strictly - see [SeriesMatchService]), the user reviews what matched, and
/// the chosen series go in with a single batch request.
class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  static void open(BuildContext context) => Navigator.of(
    context,
  ).push(AppTransitions.slideRight(const BulkImportScreen()));

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  late final SeriesMatchService _matcher = SeriesMatchService();
  late final LibraryService _library = getIt<LibraryService>();
  late final BulkImportController _controller;
  final TextEditingController _text = TextEditingController();

  ImportFormat _format = ImportFormat.auto;
  bool _useStates = true;

  /// The file the text was loaded from, if it was.
  String? _fileName;

  static const List<String> _states = DesktopImportView.states;

  /// Extensions the file picker offers, one per [ImportFormat] that reads a
  /// file.
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
    fileName: _fileName,
  );

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.trim().isEmpty || !mounted) return;
    setState(() => _fileName = null);
    _text.text = pasted;
  }

  Future<void> _openFile() async {
    final l10n = LocalizationService();
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _fileExtensions,
        dialogTitle: l10n.translate('import_open_file'),
      );
      if (file == null) return;
      final contents = ImportFileReader.readText(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _format = ImportFormat.auto;
      });
      _text.text = contents;
    } on ImportSourceException catch (e) {
      _sourceFailed(e);
    } catch (_) {
      _sourceFailed(const ImportSourceException('import_file_failed'));
    }
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
  Future<void> _fromAniList() async {
    final l10n = LocalizationService();
    final name = await _askUsername(
      title: l10n.translate('import_anilist'),
      label: l10n.translate('import_username'),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;

    final importer = AniListImporter();
    try {
      final json = await importer.fetch(name);
      if (!mounted) return;
      setState(() {
        _fileName = 'AniList · ${name.trim()}';
        _format = ImportFormat.auto;
      });
      _text.text = json;
    } on ImportSourceException catch (e) {
      _sourceFailed(e);
    } finally {
      importer.dispose();
    }
  }

  Future<String?> _askUsername({required String title, required String label}) {
    final field = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          title.toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: field,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
          style: AppTypography.sans(color: context.colors.text),
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService().translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(LocalizationService().translate('import_fetch')),
          ),
        ],
      ),
    ).whenComplete(field.dispose);
  }

  void _clearText() {
    setState(() => _fileName = null);
    _text.clear();
  }

  /// Back from the review step returns to the paste step; back from the paste
  /// step leaves the screen.
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
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, l10n.translate('failed_to_add'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    if (DesktopLayout.isActive(context)) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => !getIt<ProfileAuthService>().isLoggedIn
              ? _message(l10n.translate('import_login_required'))
              : DesktopImportView(
                  controller: _controller,
                  text: _text,
                  format: _format,
                  onFormatChanged: (f) => setState(() => _format = f),
                  useStates: _useStates,
                  onUseStatesChanged: (v) => setState(() => _useStates = v),
                  fileName: _fileName,
                  onBack: _back,
                  onPaste: _paste,
                  onOpenFile: _openFile,
                  onAniList: _fromAniList,
                  onClear: _clearText,
                  onMatch: _match,
                  onAdd: _add,
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: l10n.translate('import_list')),
      body: WidgetUtils.responsiveConstraint(
        maxWidth: 760,
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => !getIt<ProfileAuthService>().isLoggedIn
              ? _message(l10n.translate('import_login_required'))
              : (_controller.hasRows ? _results(l10n) : _input(l10n)),
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.sans(color: context.colors.textMuted),
      ),
    ),
  );

  // ─── Paste ─────────────────────────────────────────────────────────────────

  Widget _input(LocalizationService l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.translate('import_list_subtitle'),
          style: AppTypography.sans(
            color: context.colors.textMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          minLines: 10,
          maxLines: 16,
          style: AppTypography.sans(color: context.colors.text),
          decoration: InputDecoration(
            hintText: l10n.translate('import_paste_hint'),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(l10n.translate('import_paste_clipboard')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openFile,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(l10n.translate('import_open_file')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _fromAniList,
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: Text(l10n.translate('import_anilist')),
        ),
        const SizedBox(height: 16),
        _formatRow(l10n),
        _stateRow(l10n),
        if (ImportParser.carriesStates(
          _format == ImportFormat.auto
              ? ImportParser.detect(_text.text, fileName: _fileName)
              : _format,
        ))
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _useStates,
            onChanged: (v) => setState(() => _useStates = v),
            title: Text(
              l10n.translate('import_use_statuses'),
              style: AppTypography.sans(color: context.colors.text),
            ),
            subtitle: Text(
              l10n.translate('import_use_statuses_subtitle'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _text.text.trim().isEmpty ? null : _match,
          child: Text(l10n.translate('import_match').toUpperCase()),
        ),
      ],
    );
  }

  Widget _formatRow(LocalizationService l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.translate('import_format').toUpperCase(),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ),
        DropdownButton<ImportFormat>(
          value: _format,
          dropdownColor: context.colors.surface,
          underline: const SizedBox.shrink(),
          style: AppTypography.sans(color: context.colors.text),
          items: [
            for (final f in ImportFormat.values)
              DropdownMenuItem(
                value: f,
                child: Text(l10n.translate(DesktopImportView.formatKey(f))),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _format = v);
          },
        ),
      ],
    );
  }

  Widget _stateRow(LocalizationService l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.translate('import_add_as').toUpperCase(),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 11.5,
            ),
          ),
        ),
        DropdownButton<String>(
          value: _controller.state,
          dropdownColor: context.colors.surface,
          underline: const SizedBox.shrink(),
          style: AppTypography.sans(color: context.colors.text),
          items: [
            for (final s in _states)
              DropdownMenuItem(value: s, child: Text(l10n.translate(s))),
          ],
          onChanged: (v) {
            if (v != null) _controller.setTargetState(v);
          },
        ),
      ],
    );
  }

  // ─── Review ────────────────────────────────────────────────────────────────

  Widget _results(LocalizationService l10n) {
    final c = _controller;
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
            itemBuilder: (context, i) => _RowTile(
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
                    : _add,
                child: c.isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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

class _RowTile extends StatelessWidget {
  final ImportRow row;
  final LocalizationService l10n;
  final VoidCallback onToggle;
  final ValueChanged<int> onChange;

  const _RowTile({
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

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: InkWell(
        onTap: row.canSelect ? onToggle : null,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 58,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? row.query,
                      maxLines: 2,
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
                    if (_status.isNotEmpty)
                      Text(
                        _status.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: row.status == ImportRowStatus.inLibrary
                              ? context.colors.accent
                              : context.colors.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (row.candidates.length > 1)
                PopupMenuButton<int>(
                  tooltip: l10n.translate('import_change_match'),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: context.colors.textMuted,
                  ),
                  onSelected: onChange,
                  itemBuilder: (_) => [
                    for (var i = 0; i < row.candidates.length; i++)
                      PopupMenuItem(
                        value: i,
                        child: Text(
                          row.candidates[i].getDisplayTitle(
                            SettingsManager().defaultTitleLanguage,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              if (row.canSelect)
                Checkbox(value: row.selected, onChanged: (_) => onToggle())
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
