import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';
import 'package:mangabaka_app/features/library/import/import_export_tiles.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';

class ImportInputTab extends StatelessWidget {
  final LocalizationService l10n;
  final TextEditingController textController;
  final List<ImportSource> sources;
  final ImportFormat format;
  final ValueChanged<ImportFormat> onFormatChanged;
  final bool useStates;
  final ValueChanged<bool> onUseStatesChanged;
  final String? sourceLabel;
  final VoidCallback onClear;
  final VoidCallback onMatch;
  final BulkImportController controller;

  const ImportInputTab({
    super.key,
    required this.l10n,
    required this.textController,
    required this.sources,
    required this.format,
    required this.onFormatChanged,
    required this.useStates,
    required this.onUseStatesChanged,
    required this.sourceLabel,
    required this.onClear,
    required this.onMatch,
    required this.controller,
  });

  /// The theme's default input border is pill-shaped (radius 999), meant for
  /// short single-line fields — on this tall paste box it renders as a
  /// wildly exaggerated stadium shape, so it's overridden here to match the
  /// desktop paste box's rectangular radius.
  static final OutlineInputBorder _pasteFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    // Keep the floating button above Android's system navigation area.
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final list = ListView(
      // Bottom room so the floating Match button never covers the last row.
      padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + safeBottom),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.7,
          children: [for (final s in sources) MobileSourceCard(source: s)],
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
              TextButton(
                onPressed: textController.text.isEmpty ? null : onClear,
                child: Text(l10n.translate('clear').toUpperCase()),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: textController,
          minLines: 8,
          maxLines: 14,
          style: AppTypography.sans(color: context.colors.text),
          decoration: InputDecoration(
            hintText: l10n.translate('import_paste_hint'),
            filled: true,
            fillColor: context.colors.surfaceRaised,
            contentPadding: const EdgeInsets.all(18),
            border: _pasteFieldBorder,
            enabledBorder: _pasteFieldBorder,
            focusedBorder: _pasteFieldBorder,
          ),
        ),
        const SizedBox(height: 16),
        _formatRow(context),
        _stateRow(context),
        if (ImportParser.carriesStates(
          format == ImportFormat.auto
              ? ImportParser.detect(textController.text, fileName: sourceLabel)
              : format,
        ))
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: useStates,
            onChanged: onUseStatesChanged,
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
      ],
    );
    return Stack(
      children: [
        list,
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + safeBottom,
          // The disabled button is see-through; an opaque well behind it keeps
          // the content scrolling underneath from showing through.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(AppConstants.pillRadius),
            ),
            child: ElevatedButton(
              onPressed: textController.text.trim().isEmpty ? null : onMatch,
              child: Text(l10n.translate('import_match').toUpperCase()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formatRow(BuildContext context) {
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
          value: format,
          dropdownColor: context.colors.surface,
          underline: const SizedBox.shrink(),
          style: AppTypography.sans(color: context.colors.text),
          items: [
            for (final f in ImportFormat.values)
              DropdownMenuItem(
                value: f,
                child: Text(
                  l10n.translate(DesktopImportExportView.formatKey(f)),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onFormatChanged(v);
          },
        ),
      ],
    );
  }

  Widget _stateRow(BuildContext context) {
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
          value: controller.state,
          dropdownColor: context.colors.surface,
          underline: const SizedBox.shrink(),
          style: AppTypography.sans(color: context.colors.text),
          items: [
            for (final s in DesktopImportExportView.states)
              DropdownMenuItem(value: s, child: Text(l10n.translate(s))),
          ],
          onChanged: (v) {
            if (v != null) controller.setTargetState(v);
          },
        ),
      ],
    );
  }
}
