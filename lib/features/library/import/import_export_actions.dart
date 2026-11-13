import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/library/export/export_service.dart';
import 'package:mangabaka_app/features/library/import/import_export_dialogs.dart';
import 'package:mangabaka_app/features/library/import/import_sources.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<({String label, String contents})?> pickAndReadImportFile({
  required List<String> allowedExtensions,
  String? labelPrefixKey,
}) async {
  final l10n = LocalizationService();
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    dialogTitle: l10n.translate('import_open_file'),
  );
  if (file == null) return null;
  final contents = ImportFileReader.readText(await file.readAsBytes());
  final label = labelPrefixKey == null
      ? file.name
      : '${l10n.translate(labelPrefixKey)} · ${file.name}';
  return (label: label, contents: contents);
}

Future<({String label, String contents})?> fetchTrackerImportList({
  required BuildContext context,
  required String titleKey,
  required String usernameLabelKey,
  required String prefix,
  required Future<String> Function(String username) fetcher,
}) async {
  final l10n = LocalizationService();
  final name = await askImportUsernameDialog(
    context: context,
    title: l10n.translate(titleKey),
    label: l10n.translate(usernameLabelKey),
  );
  if (name == null || name.trim().isEmpty) return null;
  final json = await fetcher(name);
  return (label: '$prefix · ${name.trim()}', contents: json);
}

Future<({String label, String contents})?> fetchAniListImportList(
  BuildContext context,
) {
  final importer = AniListImporter();
  return fetchTrackerImportList(
    context: context,
    titleKey: 'import_anilist',
    usernameLabelKey: 'import_username',
    prefix: 'AniList',
    fetcher: importer.fetch,
  ).whenComplete(importer.dispose);
}

Future<({String label, String contents})?> fetchKitsuImportList(
  BuildContext context,
) {
  final importer = KitsuImporter();
  return fetchTrackerImportList(
    context: context,
    titleKey: 'import_kitsu',
    usernameLabelKey: 'import_kitsu_username',
    prefix: 'Kitsu',
    fetcher: importer.fetch,
  ).whenComplete(importer.dispose);
}

Future<int> exportLibraryToShareSheet({
  required List<LibraryEntry> filteredEntries,
  required ExportFormat format,
}) async {
  final content = ExportService.build(filteredEntries, format);
  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}/${ExportService.suggestedFileName(format)}',
  );
  await file.writeAsString(content);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: 'MangaBaka Library'),
  );
  LoggingService.logger.info(
    'Exported ${filteredEntries.length} library entries as $format',
  );
  return filteredEntries.length;
}
