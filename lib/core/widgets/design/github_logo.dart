import 'package:flutter/material.dart';

/// The GitHub mark (the Octicons `mark-github` glyph, MIT).
///
/// Material's icon set has no brand marks, and the bundled Phosphor font is
/// subset to the navigation glyphs, so the mark is drawn from its SVG path
/// rather than pulling in an SVG package for one icon.
class GithubLogo extends StatelessWidget {
  final double size;
  final Color color;

  const GithubLogo({super.key, this.size = 18, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _GithubPainter(color));
  }
}

class _GithubPainter extends CustomPainter {
  final Color color;

  _GithubPainter(this.color);

  /// The 16x16 path data.
  static const String _data =
      'M8 0c4.42 0 8 3.58 8 8a8.013 8.013 0 0 1-5.45 7.59c-.4.08-.55-.17-.55-.38 '
      '0-.27.01-1.13.01-2.2 0-.75-.25-1.23-.54-1.48 1.78-.2 3.65-.88 3.65-3.95 '
      '0-.88-.31-1.59-.82-2.15.08-.2.36-1.02-.08-2.12 0 0-.67-.22-2.2.82-.64-.18'
      '-1.32-.27-2-.27-.68 0-1.36.09-2 .27-1.53-1.03-2.2-.82-2.2-.82-.44 1.1-.16 '
      '1.92-.08 2.12-.51.56-.82 1.28-.82 2.15 0 3.06 1.86 3.75 3.64 3.95-.23.2-.44'
      '.55-.51 1.07-.46.21-1.61.55-2.33-.66-.15-.24-.6-.83-1.23-.82-.67.01-.27.38'
      '.01.53.34.19.73.9.82 1.13.16.45.68 1.31 2.69.94 0 .67.01 1.3.01 1.49 0 .21'
      '-.15.45-.55.38A7.995 7.995 0 0 1 0 8c0-4.42 3.58-8 8-8Z';

  static final Path _path = parseSvgPath(_data);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 16, size.height / 16);
    canvas.drawPath(
      _path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GithubPainter old) => old.color != color;
}

/// Builds a [Path] from SVG path data.
///
/// Supports the commands icon paths use — M, L, H, V, C, S, A and Z, absolute
/// and relative — not quadratic curves or anything else. An unsupported command
/// ends the path at that point rather than throwing, which for a fixed icon
/// would show up immediately as a truncated glyph.
Path parseSvgPath(String data) {
  final tokens = RegExp(
    r'[a-zA-Z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(data).map((m) => m.group(0)!).toList();

  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0; // current point
  var startX = 0.0, startY = 0.0; // subpath start, for Z
  var lastCx = 0.0, lastCy = 0.0; // previous cubic control point, for S
  var lastWasCubic = false;
  String? command;

  bool isCommand(String t) => RegExp(r'^[a-zA-Z]$').hasMatch(t);
  double read() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCommand(tokens[i])) command = tokens[i++];
    if (command == null) break;
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0;
    final dy = relative ? y : 0.0;

    switch (command.toUpperCase()) {
      case 'M':
        x = dx + read();
        y = dy + read();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Further coordinate pairs after a moveto are implicit linetos.
        command = relative ? 'l' : 'L';
        lastWasCubic = false;
      case 'L':
        x = dx + read();
        y = dy + read();
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'H':
        x = dx + read();
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'V':
        y = dy + read();
        path.lineTo(x, y);
        lastWasCubic = false;
      case 'C':
        final x1 = dx + read(), y1 = dy + read();
        final x2 = dx + read(), y2 = dy + read();
        final ex = dx + read(), ey = dy + read();
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
        lastWasCubic = true;
      case 'S':
        // The first control point mirrors the previous curve's second.
        final x1 = lastWasCubic ? 2 * x - lastCx : x;
        final y1 = lastWasCubic ? 2 * y - lastCy : y;
        final x2 = dx + read(), y2 = dy + read();
        final ex = dx + read(), ey = dy + read();
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
        lastWasCubic = true;
      case 'A':
        final rx = read(), ry = read();
        final rotation = read();
        final largeArc = read() != 0;
        final sweep = read() != 0;
        final ex = dx + read(), ey = dy + read();
        path.arcToPoint(
          Offset(ex, ey),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
        x = ex;
        y = ey;
        lastWasCubic = false;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastWasCubic = false;
      default:
        return path;
    }
  }
  return path;
}
