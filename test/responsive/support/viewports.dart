import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

/// The physical size is fixed, so fractional scales give fractional logical sizes.
class WindowSize {
  final Size physical;
  final double dpr;
  final double textScale;

  const WindowSize(this.physical, this.dpr, {this.textScale = 1});

  /// Rounded to physical pixels as the OS would; [jitter] lands between logical ones.
  factory WindowSize.logical(
    double width,
    double height, {
    double dpr = 1,
    int jitter = 0,
    double textScale = 1,
  }) => WindowSize(
    Size(
      (width * dpr).ceilToDouble() + jitter,
      (height * dpr).ceilToDouble() + jitter,
    ),
    dpr,
    textScale: textScale,
  );

  Size get logical => physical / dpr;

  String get label {
    String n(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    final text = textScale == 1 ? '' : ' text×${n(textScale)}';
    return '${n(logical.width)}×${n(logical.height)} @${dpr}x$text';
  }

  @override
  String toString() => label;
}

/// Floor: the runner's 1000×700 minimum (windows/runner/flutter_window.cpp).
/// Widths straddle each desktop breakpoint (1100 home rail, 1180 sidebar) by a pixel.
abstract final class WindowSizes {
  static const double minWidth = 1000;
  static const double minHeight = 700;

  static bool get exhaustive =>
      Platform.environment['RESPONSIVE_EXHAUSTIVE'] == '1';

  static const _breakpointWidths = <double>[
    1000, 1001, 1099, 1100, 1101, 1179, 1180, 1181, //
  ];

  static const _commonWidths = <double>[
    1280, 1366, 1440, 1536, 1600, 1920, 2560, 3840, //
  ];

  static const _scales = <double>[1.25, 1.5, 1.75, 2];

  static List<WindowSize> desktop() {
    if (exhaustive) return _exhaustive();
    return [
      for (final w in [..._breakpointWidths, ..._commonWidths])
        for (final h in const [minHeight, 1080.0]) WindowSize.logical(w, h),
      for (final (i, s) in _scales.indexed)
        for (final w in const [1000.0, 1180.0, 1536.0, 1920.0])
          WindowSize.logical(w, 900, dpr: s, jitter: 1 + i),
      for (final t in const [1.3, 1.5])
        for (final w in const [1000.0, 1366.0, 1920.0])
          WindowSize.logical(w, 900, textScale: t),
    ];
  }

  static List<WindowSize> _exhaustive() {
    final widths = <double>{
      ..._breakpointWidths,
      ..._commonWidths,
      for (var w = minWidth; w <= 3840; w += 37) w,
    }.toList()..sort();
    return [
      for (final w in widths)
        for (final h in const [minHeight, 900.0, 1080.0, 1440.0, 2160.0])
          WindowSize.logical(w, h),
      for (final (i, s) in _scales.indexed)
        for (final w in widths.where((w) => w <= 3840 / s + 1))
          WindowSize.logical(w, 900, dpr: s, jitter: i),
      // Windows' "make text bigger" goes to 225%.
      for (final t in const [1.25, 1.5, 2.0])
        for (final w in widths.where((w) => w <= 2600))
          WindowSize.logical(w, 900, textScale: t),
    ];
  }

  /// At a fractional scale, so most frames land on fractional logical sizes.
  static List<WindowSize> drag({double from = 2400, double to = minWidth}) {
    final steps = <WindowSize>[];
    var w = from;
    var i = 0;
    while (w > to) {
      steps.add(WindowSize.logical(w, 900, dpr: 1.25, jitter: i % 3));
      w -= 7 + (i % 5) * 3;
      i++;
    }
    steps.add(WindowSize.logical(to, 900, dpr: 1.25));
    while (w < from) {
      w = math.min(from, w + 11 + (i % 4) * 5);
      steps.add(WindowSize.logical(w, 700 + (i % 7) * 40, dpr: 1.25));
      i++;
    }
    return steps;
  }
}
