import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

mixin SeriesDetailActionsMixin<T extends StatefulWidget> on State<T> {
  LibraryService get libraryService;
  Series get series;
  bool get isAdding;
  set isAdding(bool value);

  void shareLink() {
    final l10n = LocalizationService();
    final String? link = series.links
        .whereType<String>()
        .where((l) => l.contains('mangabaka'))
        .firstOrNull;

    if (link != null) {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.instance.share(ShareParams(
        text: link,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('no_sharing_link'))));
    }
  }

  void showDeleteConfirmationDialog() {
    final l10n = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.tertiaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('delete_from_library'), style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold)),
        content: Text(l10n.translate('delete_confirmation'), style: TextStyle(color: AppConstants.textMutedColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'), style: TextStyle(color: AppConstants.textColor))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await libraryService.deleteEntry(series.id);
              if (mounted) Navigator.pop(this.context);
            },
            child: Text(l10n.translate('confirm'), style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LocalizationService().translate('copied_to_clipboard').replaceAll('{text}', text)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> addSeriesToLibrary() async {
    if (isAdding) return;
    setState(() => isAdding = true);
    try {
      await libraryService.createLibraryEntry(series.id, SettingsManager().addLibraryDefaultTab);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('failed_to_add'))),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }
}
