import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/appearance/screens/theme_editor.dart';

/// Everything the user can do to custom themes, shared by the phone, tablet
/// and desktop appearance pages so the three cannot drift apart.
class ThemeActions {
  ThemeActions._();

  static LocalizationService get _l10n => LocalizationService();
  static ThemeController get _themes => ThemeController();

  /// Opens the editor on a new theme seeded from what is on screen now, so
  /// "create" starts from something that already looks right.
  static Future<void> create(BuildContext context) {
    final current = context.colors;
    final count = _themes.customThemes.length + 1;
    return ThemeEditor.open(
      context,
      MbThemeSpec(
        id: MbThemeSpec.newId(),
        name: '${_l10n.translate('theme_editor_new_name')} $count',
        background: current.background,
        accent: current.accent,
      ),
      isNew: true,
    );
  }

  static Future<void> edit(BuildContext context, MbThemeSpec spec) =>
      ThemeEditor.open(context, spec);

  static Future<void> duplicate(MbThemeSpec spec) => _themes.saveCustom(
    spec.copyWith(id: MbThemeSpec.newId(), name: '${spec.name} 2'),
  );

  static Future<void> share(BuildContext context, MbThemeSpec spec) async {
    await Clipboard.setData(ClipboardData(text: spec.toShareCode()));
    if (context.mounted) {
      AppSnackBar.show(context, _l10n.translate('theme_code_copied'));
    }
  }

  static Future<void> delete(BuildContext context, MbThemeSpec spec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.translate('theme_delete').toUpperCase()),
        content: Text(
          _l10n.translate('theme_delete_confirm').replaceAll('{name}', spec.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: ctx.colors.textMuted,
            ),
            child: Text(_l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colors.error),
            child: Text(_l10n.translate('theme_delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) await _themes.deleteCustom(spec.id);
  }

  /// Asks for a theme code, prefilled from the clipboard when it holds one.
  static Future<void> import(BuildContext context) async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final prefill = (clip?.text ?? '').trim().startsWith('mbtheme1:')
        ? clip!.text!.trim()
        : '';
    if (!context.mounted) return;
    final field = TextEditingController(text: prefill);
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.translate('theme_import').toUpperCase()),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: field,
            autofocus: prefill.isEmpty,
            minLines: 2,
            maxLines: 4,
            style: AppTypography.sans(color: ctx.colors.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: _l10n.translate('theme_import_hint'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: ctx.colors.textMuted,
            ),
            child: Text(_l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, field.text),
            child: Text(_l10n.translate('theme_import')),
          ),
        ],
      ),
    );
    field.dispose();
    if (code == null || code.trim().isEmpty) return;
    final spec = await _themes.importShareCode(code);
    if (!context.mounted) return;
    if (spec == null) {
      AppSnackBar.show(
        context,
        _l10n.translate('theme_import_invalid'),
        isError: true,
      );
      return;
    }
    await _themes.apply(spec.id, spec.brightness);
    if (context.mounted) {
      AppSnackBar.show(context, _l10n.translate('theme_imported'));
    }
  }

  /// Edit / duplicate / share / delete, anchored at [position].
  static Future<void> showCustomMenu(
    BuildContext context,
    MbThemeSpec spec,
    Offset position,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final c = context.colors;
    PopupMenuItem<String> item(String value, IconData icon, String key,
            {Color? color}) =>
        PopupMenuItem(
          value: value,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color ?? c.textMuted),
              const SizedBox(width: 12),
              Text(_l10n.translate(key), style: TextStyle(color: color)),
            ],
          ),
        );

    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        item('edit', Icons.edit_rounded, 'theme_edit'),
        item('duplicate', Icons.copy_all_rounded, 'theme_duplicate'),
        item('share', Icons.ios_share_rounded, 'theme_share'),
        item('delete', Icons.delete_outline_rounded, 'theme_delete',
            color: c.error),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        await edit(context, spec);
      case 'duplicate':
        await duplicate(spec);
      case 'share':
        await share(context, spec);
      case 'delete':
        await delete(context, spec);
    }
  }
}
