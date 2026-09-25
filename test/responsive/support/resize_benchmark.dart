import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_sweep.dart';
import 'viewports.dart';

/// What one drag-resize cost, per frame.
class ResizeCost {
  final String label;

  /// Wall time of each frame (build + layout + paint on the UI thread).
  final List<Duration> frames;

  /// Elements rebuilt in each frame.
  final List<int> rebuilds;

  ResizeCost(this.label, this.frames, this.rebuilds);

  double _ms(Duration d) => d.inMicroseconds / 1000;

  double get meanMs => frames.map(_ms).reduce((a, b) => a + b) / frames.length;

  double percentileMs(double p) {
    final sorted = frames.map(_ms).toList()..sort();
    return sorted[math.min(sorted.length - 1, (sorted.length * p).floor())];
  }

  double get meanRebuilds => rebuilds.reduce((a, b) => a + b) / rebuilds.length;

  int get maxRebuilds => rebuilds.reduce(math.max);

  /// The typical frame: breakpoint crossings (which rebuild on purpose) are
  /// rare in a drag, so they don't move the median.
  int get medianRebuilds {
    final sorted = [...rebuilds]..sort();
    return sorted[sorted.length ~/ 2];
  }

  String row() =>
      '${label.padRight(28)} '
      '${frames.length.toString().padLeft(4)} frames  '
      'mean ${meanMs.toStringAsFixed(2).padLeft(6)} ms  '
      'p90 ${percentileMs(0.9).toStringAsFixed(2).padLeft(6)} ms  '
      'max ${percentileMs(1).toStringAsFixed(2).padLeft(6)} ms  '
      'rebuilds/frame median ${medianRebuilds.toString().padLeft(4)} '
      'mean ${meanRebuilds.toStringAsFixed(0).padLeft(4)} '
      'max ${maxRebuilds.toString().padLeft(4)}';
}

/// Drag-resizes the pumped app along [path] and measures each frame.
///
/// Frames are timed in the test's debug build, so absolute numbers run well
/// above a release build's; they are for comparing layouts and changes, not
/// for reading as real frame times. The first [warmUp] frames are discarded
/// (JIT warm-up, image placeholders settling).
Future<ResizeCost> measureDrag(
  WidgetTester tester,
  String label, {
  List<WindowSize>? path,
  int warmUp = 20,
}) async {
  final steps = path ?? WindowSizes.drag();
  final frames = <Duration>[];
  final rebuilds = <int>[];
  var count = 0;
  // RESIZE_BENCHMARK_DETAIL=1: which widgets rebuild, and whose build
  // (nearest State/Stateless ancestor with a source location) caused it.
  final detail = Platform.environment['RESIZE_BENCHMARK_DETAIL'] == '1';
  final byType = <String, int>{};
  final previous = debugOnRebuildDirtyWidget;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    count++;
    if (detail) {
      final key = element.widget.runtimeType.toString();
      byType[key] = (byType[key] ?? 0) + 1;
    }
  };
  final watch = Stopwatch();
  try {
    for (final (i, v) in steps.indexed) {
      applyViewport(tester, v);
      count = 0;
      watch
        ..reset()
        ..start();
      await tester.pump();
      watch.stop();
      if (i >= warmUp) {
        frames.add(watch.elapsed);
        rebuilds.add(count);
      }
    }
  } finally {
    debugOnRebuildDirtyWidget = previous;
  }
  if (detail) {
    final top = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final n = steps.length;
    // ignore: avoid_print
    print(
      '$label — rebuilds per frame by widget:\n'
      '${top.take(30).map((e) => '  ${(e.value / n).toStringAsFixed(1).padLeft(7)}  ${e.key}').join('\n')}',
    );
  }
  return ResizeCost(label, frames, rebuilds);
}
