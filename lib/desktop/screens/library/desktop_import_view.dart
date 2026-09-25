import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The bulk importer on desktop.
///
/// The phone's importer is one narrow column: a paste box over a state
/// dropdown over a button. On a wide window that is a lot of empty space and a
/// stock Material dropdown, so here the source sits beside its options, and
/// everything is built from the desktop's own controls.
///
/// Stateless on purpose: the screen that owns the controller and the text also
/// serves the phone, so it keeps the state and hands this view what to show.
class DesktopImportView extends StatelessWidget {
  final BulkImportController controller;
  final TextEditingController text;

  final ImportFormat format;
  final ValueChanged<ImportFormat> onFormatChanged;
  final bool useStates;
  final ValueChanged<bool> onUseStatesChanged;

  /// The file the text was loaded from, shown beside the file button.
  final String? fileName;

  final VoidCallback onBack;
  final VoidCallback onPaste;
  final VoidCallback onOpenFile;
  final VoidCallback onAniList;
  final VoidCallback onClear;
  final VoidCallback onMatch;
  final VoidCallback onAdd;

  static const List<String> states = [
    'plan_to_read',
    'reading',
    'completed',
    'paused',
    'dropped',
    'rereading',
    'considering',
  ];

  const DesktopImportView({
    super.key,
    required this.controller,
    required this.text,
    required this.format,
    required this.onFormatChanged,
    required this.useStates,
    required this.onUseStatesChanged,
    required this.fileName,
    required this.onBack,
    required this.onPaste,
    required this.onOpenFile,
    required this.onAniList,
    required this.onClear,
    required this.onMatch,
    required this.onAdd,
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

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final review = controller.hasRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPageHeader(
          title: l10n.translate('import_list'),
          subtitle: review
              ? l10n
                    .translate('import_summary')
                    .replaceAll('{selected}', '${controller.selectedCount}')
                    .replaceAll('{total}', '${controller.rows.length}')
              : l10n.translate('import_list_subtitle'),
          leading: DesktopIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: l10n.translate('back'),
            onPressed: onBack,
            filled: true,
          ),
          actions: review ? _reviewActions(context, l10n) : const [],
        ),
        Expanded(
          child: review ? _review(context, l10n) : _input(context, l10n),
        ),
      ],
    );
  }

  // ─── Input ───────────────────────────────────────────────────────────────

  Widget _input(BuildContext context, LocalizationService l10n) {
    final detected = format == ImportFormat.auto
        ? ImportParser.detect(text.text, fileName: fileName)
        : format;
    final titleCount = ImportParser.parse(
      text.text,
      format: format,
      useStates: useStates,
      fileName: fileName,
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
                  // The sources wrap onto a second line in a narrow window
                  // rather than overflowing into the preview beside them;
                  // Clear keeps the right edge.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DesktopPillButton(
                              label: l10n.translate('import_paste_clipboard'),
                              icon: Icons.content_paste_rounded,
                              onPressed: onPaste,
                            ),
                            DesktopPillButton(
                              label: l10n.translate('import_open_file'),
                              icon: Icons.folder_open_rounded,
                              onPressed: onOpenFile,
                            ),
                            DesktopPillButton(
                              label: l10n.translate('import_anilist'),
                              icon: Icons.cloud_download_outlined,
                              onPressed: onAniList,
                            ),
                            if (fileName != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  fileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.sans(
                                    color: context.colors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      DesktopPillButton(
                        label: l10n.translate('clear'),
                        icon: Icons.close_rounded,
                        onPressed: text.text.isEmpty ? null : onClear,
                      ),
                    ],
                  ),
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
          SizedBox(width: 320, child: _options(context, l10n, titleCount)),
        ],
      ),
    );
  }

  static final OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  Widget _options(
    BuildContext context,
    LocalizationService l10n,
    int titleCount,
  ) {
    final canUseStates = ImportParser.carriesStates(
      format == ImportFormat.auto
          ? ImportParser.detect(text.text, fileName: fileName)
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
