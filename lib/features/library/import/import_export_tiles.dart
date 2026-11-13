import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';
import 'package:mangabaka_app/features/library/import/bulk_import_controller.dart';

class MobileSourceCard extends StatelessWidget {
  final ImportSource source;

  const MobileSourceCard({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: InkWell(
        onTap: source.onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ImportSourceIcon(source: source, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.translate(source.labelKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      l10n.translate(source.hintKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExportFormatTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ExportFormatTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.colors.surfaceRaised : context.colors.surface,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportRowTile extends StatelessWidget {
  final ImportRow row;
  final LocalizationService l10n;
  final VoidCallback onToggle;
  final ValueChanged<int> onChange;

  const ImportRowTile({
    super.key,
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
