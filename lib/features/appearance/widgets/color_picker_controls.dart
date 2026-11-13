import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ColorPickerSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const ColorPickerSwatch({
    super.key,
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
class ColorPickerSvSquare extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const ColorPickerSvSquare({
    super.key,
    required this.hsv,
    required this.onChanged,
  });

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

class ColorPickerHueSlider extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  const ColorPickerHueSlider({
    super.key,
    required this.hsv,
    required this.onChanged,
  });

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
