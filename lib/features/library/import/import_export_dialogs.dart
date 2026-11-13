import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/screens/library/desktop_import_export_view.dart';

typedef OpenFileAsCallback =
    Future<void> Function({
      required List<String> extensions,
      required String labelKey,
    });

List<ImportSource> buildImportSources({
  required VoidCallback onAniList,
  required VoidCallback onKitsu,
  required OpenFileAsCallback onOpenFileAs,
  required VoidCallback onPaste,
  required VoidCallback onOpenFile,
}) => [
  ImportSource(
    icon: Icons.cloud_download_outlined,
    logoAsset: 'assets/import/anilist.png',
    labelKey: 'import_anilist',
    hintKey: 'import_anilist_hint',
    onTap: onAniList,
  ),
  ImportSource(
    icon: Icons.cloud_download_outlined,
    logoAsset: 'assets/import/kitsu.png',
    labelKey: 'import_kitsu',
    hintKey: 'import_kitsu_hint',
    onTap: onKitsu,
  ),
  ImportSource(
    icon: Icons.description_outlined,
    logoAsset: 'assets/import/myanimelist.png',
    labelKey: 'import_mal',
    hintKey: 'import_mal_hint',
    onTap: () =>
        onOpenFileAs(extensions: const ['xml', 'gz'], labelKey: 'import_mal'),
  ),
  ImportSource(
    icon: Icons.description_outlined,
    logoAsset: 'assets/import/mangaupdates.png',
    labelKey: 'import_mangaupdates',
    hintKey: 'import_mangaupdates_hint',
    onTap: () => onOpenFileAs(
      extensions: const ['json'],
      labelKey: 'import_mangaupdates',
    ),
  ),
  ImportSource(
    icon: Icons.description_outlined,
    logoAsset: 'assets/import/mihon.png',
    labelKey: 'import_mihon',
    hintKey: 'import_mihon_hint',
    onTap: () => onOpenFileAs(
      extensions: const ['tachibk', 'proto', 'gz'],
      labelKey: 'import_mihon',
    ),
  ),
  ImportSource(
    icon: Icons.description_outlined,
    logoAsset: 'assets/import/comick.webp',
    labelKey: 'import_comick',
    hintKey: 'import_comick_hint',
    onTap: () => onOpenFileAs(
      extensions: const ['json', 'csv'],
      labelKey: 'import_comick',
    ),
  ),
  ImportSource(
    icon: Icons.content_paste_rounded,
    labelKey: 'import_paste_clipboard',
    hintKey: 'import_paste_hint_short',
    onTap: onPaste,
  ),
  ImportSource(
    icon: Icons.folder_open_rounded,
    labelKey: 'import_open_file',
    hintKey: 'import_open_file_hint',
    onTap: onOpenFile,
  ),
];

Future<String?> askImportUsernameDialog({
  required BuildContext context,
  required String title,
  required String label,
}) {
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
