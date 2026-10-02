import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Stroke icons from Lucide (ISC, https://lucide.dev) — the set mangabaka.org
/// uses for its feature shortcuts — drawn straight from their SVG path data
/// so they match the site exactly, without an SVG package.
///
/// Each icon is a list of path strings on Lucide's 24×24 grid, stroked 2 wide
/// with round caps and joins and no fill.
@immutable
class LucideGlyph {
  final List<String> paths;

  const LucideGlyph(this.paths);

  static const flaskConical = LucideGlyph([
    'M14 2v6a2 2 0 0 0 .245.96l5.51 10.08A2 2 0 0 1 18 22H6a2 2 0 0 1-1.755-2.96l5.51-10.08A2 2 0 0 0 10 8V2',
    'M6.453 15h11.094',
    'M8.5 2h7',
  ]);

  static const star = LucideGlyph([
    'M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z',
  ]);

  static const heart = LucideGlyph([
    'M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5',
  ]);

  static const dices = LucideGlyph([
    // The front die (a rounded 12×12 square at 2,10).
    'M4 10h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2z',
    'm17.92 14 3.5-3.5a2.24 2.24 0 0 0 0-3l-5-4.92a2.24 2.24 0 0 0-3 0L10 6',
    'M6 18h.01',
    'M10 14h.01',
    'M15 6h.01',
    'M18 9h.01',
  ]);
}

/// A [LucideGlyph] at [size], in [color] — both default to the surrounding
/// [IconTheme], like a Material [Icon].
class MbLucideIcon extends StatelessWidget {
  final LucideGlyph glyph;
  final double? size;
  final Color? color;

  const MbLucideIcon(this.glyph, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _LucidePainter(
          paths: _parsed(glyph),
          color: color ?? theme.color ?? context.colors.text,
        ),
      ),
    );
  }

  /// Parsed once per glyph; the same few icons are drawn over and over.
  static final Map<LucideGlyph, List<Path>> _cache = {};

  static List<Path> _parsed(LucideGlyph glyph) =>
      _cache.putIfAbsent(glyph, () => [for (final d in glyph.paths) _parse(d)]);
}

class _LucidePainter extends CustomPainter {
  final List<Path> paths;
  final Color color;

  const _LucidePainter({required this.paths, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2
      ..color = color;
    canvas.save();
    canvas.scale(scale);
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LucidePainter old) =>
      old.color != color || old.paths != paths;
}

final RegExp _token = RegExp(r'[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// Reads SVG path data: M L H V C S Q A Z, absolute and relative.
Path _parse(String d) {
  final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0; // current point
  var startX = 0.0, startY = 0.0; // subpath start, for Z
  var lastCtrlX = 0.0, lastCtrlY = 0.0; // last cubic control, for S
  var lastCmd = '';
  var cmd = '';

  double num() => double.parse(tokens[i++]);
  bool flag() => num() != 0;

  while (i < tokens.length) {
    if (RegExp(r'[a-zA-Z]').hasMatch(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final op = cmd.toUpperCase();

    switch (op) {
      case 'M':
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = startX = nx;
        y = startY = ny;
        // Further coordinate pairs after a moveto are implicit linetos.
        cmd = rel ? 'l' : 'L';
      case 'L':
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
      case 'H':
        final nx = num() + (rel ? x : 0);
        path.lineTo(nx, y);
        x = nx;
      case 'V':
        final ny = num() + (rel ? y : 0);
        path.lineTo(x, ny);
        y = ny;
      case 'C':
        final x1 = num() + (rel ? x : 0), y1 = num() + (rel ? y : 0);
        final x2 = num() + (rel ? x : 0), y2 = num() + (rel ? y : 0);
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastCtrlX = x2;
        lastCtrlY = y2;
        x = nx;
        y = ny;
      case 'S':
        final reflect = lastCmd == 'C' || lastCmd == 'S';
        final x1 = reflect ? 2 * x - lastCtrlX : x;
        final y1 = reflect ? 2 * y - lastCtrlY : y;
        final x2 = num() + (rel ? x : 0), y2 = num() + (rel ? y : 0);
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lastCtrlX = x2;
        lastCtrlY = y2;
        x = nx;
        y = ny;
      case 'Q':
        final x1 = num() + (rel ? x : 0), y1 = num() + (rel ? y : 0);
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.quadraticBezierTo(x1, y1, nx, ny);
        x = nx;
        y = ny;
      case 'A':
        final rx = num(), ry = num(), rotation = num();
        final largeArc = flag(), sweep = flag();
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.arcToPoint(
          Offset(nx, ny),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
        x = nx;
        y = ny;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Unsupported path command "$cmd" in "$d"');
    }
    lastCmd = op;
  }
  return path;
}
