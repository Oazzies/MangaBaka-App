import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_editor_controls.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_live_preview.dart';

/// The draft being edited: the seeds the user picks, and the palette derived
/// from them on every change.
class ThemeEditorController extends ChangeNotifier {
  MbThemeSpec _spec;
  late MbPalette _palette = _spec.palette;

  ThemeEditorController(this._spec);

  MbThemeSpec get spec => _spec;
  MbPalette get palette => _palette;

  /// True when derivation had to nudge a picked colour for legibility, so the
  /// editor can say why the preview differs slightly from the swatch.
  bool get adjusted =>
      _palette.accent != _spec.accent ||
      (_spec.text != null && _palette.text != _spec.text);

  void _update(MbThemeSpec next) {
    _spec = next;
    _palette = next.palette;
    notifyListeners();
  }

  void setName(String name) => _spec = _spec.copyWith(name: name);
  void setBackground(Color c) => _update(_spec.copyWith(background: c));
  void setAccent(Color c) => _update(_spec.copyWith(accent: c));
  void setSurface(Color? c) => _update(
    c == null ? _spec.copyWith(clearSurface: true) : _spec.copyWith(surface: c),
  );
  void setText(Color? c) => _update(
    c == null ? _spec.copyWith(clearText: true) : _spec.copyWith(text: c),
  );
}

/// Creates or edits a custom theme.
///
/// Opens as a large two-pane dialog in the desktop shell, and as a full
/// screen elsewhere — side by side on tablets and in landscape, stacked on
/// phones.
class ThemeEditor {
  ThemeEditor._();

  static Future<void> open(
    BuildContext context,
    MbThemeSpec spec, {
    bool isNew = false,
  }) async {
    final controller = ThemeEditorController(spec);
    final saved = DesktopLayout.isActive(context)
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) => Dialog(
              insetPadding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 980,
                  maxHeight: 720,
                ),
                child: _EditorDialogBody(controller: controller),
              ),
            ),
          )
        : await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => _EditorScreen(controller: controller),
            ),
          );
    if (saved == true) {
      final themes = ThemeController();
      final s = controller.spec;
      await themes.saveCustom(s);
      // A new theme is applied straight away — that is what "create" means.
      // An edit to the theme already in use shows up by itself.
      if (isNew) await themes.apply(s.id, s.brightness);
    }
    controller.dispose();
  }
}

class _EditorScreen extends StatelessWidget {
  final ThemeEditorController controller;
  const _EditorScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Scaffold(
      appBar: mbScreenAppBar(
        title: l10n.translate('theme_editor_title'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('save')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final sideBySide = box.maxWidth >= 700;
            final preview = ListenableBuilder(
              listenable: controller,
              builder: (_, _) => ThemeLivePreview(palette: controller.palette),
            );
            final controls = ThemeEditorControls(controller: controller);
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: preview,
                    ),
                  ),
                  SizedBox(
                    width: (box.maxWidth * 0.45).clamp(320, 460),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                      children: [controls],
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.horizontalPadding,
                8,
                AppConstants.horizontalPadding,
                32,
              ),
              children: [preview, const SizedBox(height: 20), controls],
            );
          },
        ),
      ),
    );
  }
}

class _EditorDialogBody extends StatelessWidget {
  final ThemeEditorController controller;
  const _EditorDialogBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('theme_editor_title').toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ListenableBuilder(
                      listenable: controller,
                      builder: (_, _) =>
                          ThemeLivePreview(palette: controller.palette),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: ThemeEditorControls(controller: controller),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Fixed widths: the Mb buttons fill their slot, and a bare Row
          // would give them unbounded width.
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 160,
                child: MbSecondaryButton(
                  label: l10n.translate('cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: MbPrimaryButton(
                  label: l10n.translate('save'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
