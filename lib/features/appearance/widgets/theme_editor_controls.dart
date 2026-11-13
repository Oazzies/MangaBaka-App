import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/mb_theme_spec.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/appearance/screens/theme_editor.dart';
import 'package:mangabaka_app/features/appearance/widgets/mb_color_picker.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_color_row.dart';

class ThemeEditorControls extends StatefulWidget {
  final ThemeEditorController controller;
  const ThemeEditorControls({super.key, required this.controller});

  @override
  State<ThemeEditorControls> createState() => _ThemeEditorControlsState();
}

class _ThemeEditorControlsState extends State<ThemeEditorControls> {
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
            ThemeColorRow(
              label: l10n.translate('theme_background'),
              color: spec.background,
              onTap: () => _pick(
                'theme_background',
                spec.background,
                ctrl.setBackground,
              ),
            ),
            ThemeColorRow(
              label: l10n.translate('theme_accent'),
              color: p.accent,
              onTap: () => _pick(
                'theme_accent',
                spec.accent,
                ctrl.setAccent,
                contrastAgainst: p.surface,
              ),
            ),
            ThemeColorRow(
              label: l10n.translate('theme_surface'),
              color: p.surface,
              isAuto: spec.surface == null,
              onAuto: () => ctrl.setSurface(null),
              onTap: () => _pick('theme_surface', p.surface, ctrl.setSurface),
            ),
            ThemeColorRow(
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
