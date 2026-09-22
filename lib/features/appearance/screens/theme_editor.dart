import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/appearance/widgets/mb_color_picker.dart';
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
            final controls = _EditorControls(controller: controller);
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
                    child: _EditorControls(controller: controller),
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

class _EditorControls extends StatefulWidget {
  final ThemeEditorController controller;
  const _EditorControls({required this.controller});

  @override
  State<_EditorControls> createState() => _EditorControlsState();
}

class _EditorControlsState extends State<_EditorControls> {
  late final TextEditingController _name = TextEditingController(
    text: widget.controller.spec.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(
    String titleKey,
    Color initial,
    ValueChanged<Color> onPicked, {
    Color? contrastAgainst,
  }) async {
    final picked = await showMbColorPicker(
      context,
      initial: initial,
      title: LocalizationService().translate(titleKey),
      contrastAgainst: contrastAgainst,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final ctrl = widget.controller;
    final c = context.colors;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final spec = ctrl.spec;
        final p = ctrl.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label(context, l10n.translate('theme_name')),
            TextField(
              controller: _name,
              maxLength: MbThemeSpec.maxNameLength,
              style: AppTypography.sans(color: c.text, fontSize: 15),
              decoration: const InputDecoration(counterText: ''),
              onChanged: ctrl.setName,
            ),
            const SizedBox(height: 20),
            _ColorRow(
              label: l10n.translate('theme_background'),
              color: spec.background,
              onTap: () => _pick(
                'theme_background',
                spec.background,
                ctrl.setBackground,
              ),
            ),
            _ColorRow(
              label: l10n.translate('theme_accent'),
              color: p.accent,
              onTap: () => _pick(
                'theme_accent',
                spec.accent,
                ctrl.setAccent,
                contrastAgainst: p.surface,
              ),
            ),
            _ColorRow(
              label: l10n.translate('theme_surface'),
              color: p.surface,
              isAuto: spec.surface == null,
              onAuto: () => ctrl.setSurface(null),
              onTap: () => _pick('theme_surface', p.surface, ctrl.setSurface),
            ),
            _ColorRow(
              label: l10n.translate('theme_text'),
              color: p.text,
              isAuto: spec.text == null,
              onAuto: () => ctrl.setText(null),
              onTap: () => _pick(
                'theme_text',
                p.text,
                ctrl.setText,
                contrastAgainst: p.background,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: ctrl.adjusted
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: c.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.translate('theme_contrast_adjusted'),
                              style: AppTypography.sans(
                                color: c.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.monoLabel(
        color: context.colors.textMuted,
        fontSize: 11.5,
      ),
    ),
  );
}

/// One editable colour: swatch, name, hex, and an optional "auto" reset for
/// the tokens that are derived unless the user overrides them.
class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool? isAuto;
  final VoidCallback? onAuto;

  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.isAuto,
    this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = LocalizationService();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Outlined rather than filled: the rows sit on the page background on
      // phones but on a surface-coloured dialog on desktop.
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.sans(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isAuto == true
                            ? l10n.translate('theme_auto_hint')
                            : ColorMath.toHex(color),
                        style: AppTypography.sans(
                          color: c.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuto != null)
                  _AutoChip(active: isAuto!, onTap: isAuto! ? null : onAuto),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoChip extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _AutoChip({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.accent : c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Text(
          LocalizationService().translate('theme_auto').toUpperCase(),
          style: AppTypography.display(
            color: active ? c.onAccent : c.textMuted,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
