import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/palette/color_math.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/appearance/widgets/color_picker_controls.dart';

/// Opens a colour picker suited to the platform: a bottom sheet on phones,
/// a dialog on tablets, landscape and desktop. Resolves the chosen colour, or
/// null if dismissed.
///
/// [contrastAgainst], when given, shows a live contrast-ratio readout — the
/// editor passes the background so the user sees legibility as they drag.
Future<Color?> showMbColorPicker(
  BuildContext context, {
  required Color initial,
  String? title,
  Color? contrastAgainst,
}) {
  final l10n = LocalizationService();
  final size = MediaQuery.sizeOf(context);
  final useSheet =
      !DesktopLayout.isDesktopPlatform &&
      size.width < 600 &&
      size.height > size.width;

  Widget body(BuildContext ctx) => _PickerBody(
    initial: initial,
    title: title ?? l10n.translate('color_picker_title'),
    contrastAgainst: contrastAgainst,
  );

  if (useSheet) {
    return showAdaptiveSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: body(ctx),
      ),
    );
  }
  return showDialog<Color>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: body(ctx),
      ),
    ),
  );
}

class _PickerBody extends StatefulWidget {
  final Color initial;
  final String title;
  final Color? contrastAgainst;

  const _PickerBody({
    required this.initial,
    required this.title,
    this.contrastAgainst,
  });

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late Color _color = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title.toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          MbColorPicker(
            color: _color,
            contrastAgainst: widget.contrastAgainst,
            onChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MbSecondaryButton(
                  label: l10n.translate('cancel'),
                  expand: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MbPrimaryButton(
                  label: l10n.translate('apply'),
                  expand: true,
                  onPressed: () => Navigator.pop(context, _color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Saturation/value square, hue slider, hex field and swatches.
///
/// Stateless about the colour itself: the caller owns [color] and gets every
/// change through [onChanged], so the editor can preview live.
class MbColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  final Color? contrastAgainst;

  const MbColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.contrastAgainst,
  });

  @override
  State<MbColorPicker> createState() => _MbColorPickerState();
}

class _MbColorPickerState extends State<MbColorPicker> {
  /// Kept separately from the incoming colour: converting a greyscale colour
  /// to HSV loses its hue, which would snap the hue slider to red while the
  /// user drags value toward black.
  late HSVColor _hsv = HSVColor.fromColor(widget.color);
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(widget.color),
  );

  static String _hexOf(Color c) => ColorMath.toHex(c).substring(1);

  @override
  void didUpdateWidget(MbColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.color != _hsv.toColor()) {
      final next = HSVColor.fromColor(widget.color);
      _hsv = next.saturation == 0 ? next.withHue(_hsv.hue) : next;
      final hex = _hexOf(widget.color);
      if (_hex.text.toUpperCase() != hex) _hex.text = hex;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor hsv) {
    setState(() => _hsv = hsv);
    final c = hsv.toColor();
    _hex.text = _hexOf(c);
    widget.onChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _hsv.toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1.6,
          child: ColorPickerSvSquare(hsv: _hsv, onChanged: _set),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 28,
          child: ColorPickerHueSlider(hsv: _hsv, onChanged: _set),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppConstants.denseRadius),
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hex,
                style: AppTypography.sans(color: c.text, fontSize: 15),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  prefixText: '#',
                  prefixStyle: AppTypography.sans(
                    color: c.textMuted,
                    fontSize: 15,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) {
                  final parsed = ColorMath.parseHex(v);
                  if (parsed == null || v.length != 6) return;
                  final next = HSVColor.fromColor(parsed);
                  setState(() => _hsv = next);
                  widget.onChanged(parsed);
                },
              ),
            ),
            if (widget.contrastAgainst != null) ...[
              const SizedBox(width: 12),
              _ContrastBadge(
                ratio: ColorMath.contrast(color, widget.contrastAgainst!),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in ThemePresets.accentSwatches)
              ColorPickerSwatch(
                color: s,
                selected: s == color,
                onTap: () => _set(HSVColor.fromColor(s)),
              ),
          ],
        ),
      ],
    );
  }
}

class _ContrastBadge extends StatelessWidget {
  final double ratio;
  const _ContrastBadge({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ok = ratio >= 4.5;
    final tone = ok ? c.success : (ratio >= 3 ? c.warning : c.error);
    return Tooltip(
      message: LocalizationService()
          .translate('contrast_ratio')
          .replaceAll('{ratio}', ratio.toStringAsFixed(1)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Text(
          '${ratio.toStringAsFixed(1)}:1',
          style: AppTypography.sans(
            color: tone,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
