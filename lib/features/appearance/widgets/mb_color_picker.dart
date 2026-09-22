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
  final useSheet = !DesktopLayout.isDesktopPlatform &&
      size.width < 600 &&
      size.height > size.width;

  Widget body(BuildContext ctx) => _PickerBody(
    initial: initial,
    title: title ?? l10n.translate('color_picker_title'),
    contrastAgainst: contrastAgainst,
  );

  if (useSheet) {
    return showModalBottomSheet<Color>(
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
  late final TextEditingController _hex =
      TextEditingController(text: _hexOf(widget.color));

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
          child: _SvSquare(hsv: _hsv, onChanged: _set),
        ),
        const SizedBox(height: 14),
        SizedBox(height: 28, child: _HueSlider(hsv: _hsv, onChanged: _set)),
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
              _Swatch(
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

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.colors.text : context.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

/// Drag anywhere to set saturation (x) and value (y) at the current hue.
class _SvSquare extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const _SvSquare({required this.hsv, required this.onChanged});

  void _update(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = 1 - (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition, size),
          onPanUpdate: (d) => _update(d.localPosition, size),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
            child: CustomPaint(
              size: size,
              painter: _SvPainter(hsv: hsv, ring: context.colors.border),
            ),
          ),
        );
      },
    );
  }
}

class _SvPainter extends CustomPainter {
  final HSVColor hsv;
  final Color ring;

  _SvPainter({required this.hsv, required this.ring});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFFFFFF), hue],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
        ).createShader(rect),
    );
    final thumb = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      thumb,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      thumb,
      10.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66000000),
    );
  }

  @override
  bool shouldRepaint(_SvPainter old) => old.hsv != hsv || old.ring != ring;
}

class _HueSlider extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const _HueSlider({required this.hsv, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        void update(Offset p) =>
            onChanged(hsv.withHue((p.dx / w).clamp(0.0, 1.0) * 359.9));
        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: CustomPaint(
            size: Size(w, box.maxHeight),
            painter: _HuePainter(hue: hsv.hue),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  final double hue;
  _HuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final track = Rect.fromLTWH(0, size.height / 2 - 7, size.width, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble() % 360, 1, 1).toColor(),
          ],
        ).createShader(track),
    );
    final x = (hue / 360) * size.width;
    final center = Offset(x.clamp(7, size.width - 7), size.height / 2);
    canvas.drawCircle(
      center,
      11,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}
