import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';

import 'viewports.dart';

class LayoutIssue {
  final String scenario;
  final WindowSize viewport;

  /// Size-specific values normalised out, so repeats of one bug group together.
  final String key;

  final String? location;

  final String detail;

  LayoutIssue({
    required this.scenario,
    required this.viewport,
    required this.key,
    required this.location,
    required this.detail,
  });
}

/// Call [attach] before the first pump, so load-time errors keep their full detail.
class IssueLog {
  final List<LayoutIssue> issues = [];

  String scenario = 'initial load';
  WindowSize? viewport;

  FlutterExceptionHandler? _previous;

  void attach(WidgetTester tester) {
    _previous = FlutterError.onError;
    FlutterError.onError = (details) =>
        issues.add(_fromError(scenario, viewport!, details));
    // The test fails if the handler it installed isn't back when it ends.
    addTearDown(detach);
  }

  void detach() {
    if (_previous == null) return;
    FlutterError.onError = _previous;
    _previous = null;
  }

  void addAll(Iterable<LayoutIssue> more) => issues.addAll(more);

  /// Reports every issue grouped: a bug spans a band of sizes, which diagnoses it.
  void expectClean() {
    if (issues.isEmpty) return;
    final groups = <String, List<LayoutIssue>>{};
    for (final i in issues) {
      (groups['${i.key}\n${i.location ?? ''}'] ??= []).add(i);
    }
    final out = StringBuffer(
      '${groups.length} distinct layout issue(s), '
      '${issues.length} occurrence(s):\n',
    );
    var n = 0;
    for (final g in groups.values) {
      n++;
      final first = g.first;
      out.writeln('\n[$n] ${first.key}');
      if (first.location != null) out.writeln('    at ${first.location}');
      final seen = g.map((i) => '${i.scenario} @ ${i.viewport}').toSet();
      out.writeln(
        '    first seen (${seen.length}): '
        '${seen.take(8).join('; ')}${seen.length > 8 ? '; …' : ''}',
      );
      out.writeln(_indent(_trim(first.detail)));
    }
    fail(out.toString());
  }

  static String _trim(String s) {
    final lines = s.split('\n');
    return lines.take(40).join('\n') + (lines.length > 40 ? '\n…' : '');
  }

  static String _indent(String s) =>
      s.split('\n').map((l) => '      $l').join('\n');
}

void applyViewport(WidgetTester tester, WindowSize v) {
  tester.view.devicePixelRatio = v.dpr;
  tester.view.physicalSize = v.physical;
  tester.platformDispatcher.textScaleFactorTestValue = v.textScale;
}

void resetViewport(WidgetTester tester) {
  tester.view.reset();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}

/// Resizes in order, as a drag does, not fresh per size. [log] must be attached.
Future<void> sweep(
  WidgetTester tester,
  IssueLog log, {
  required String scenario,
  required List<WindowSize> viewports,
  bool checkControls = true,
}) async {
  log.scenario = scenario;
  for (final v in viewports) {
    log.viewport = v;
    applyViewport(tester, v);
    // Two frames: the resize, then what it scheduled after layout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    if (checkControls) {
      // Let transitions finish: a control covered mid-animation isn't stuck.
      await tester.pump(const Duration(milliseconds: 600));
      log.addAll(unreachableControls(tester, scenario: scenario, viewport: v));
    }
  }
}

LayoutIssue _fromError(String scenario, WindowSize v, FlutterErrorDetails d) {
  final text = d.toString();
  final summary = d.exceptionAsString().split('\n').first;
  final location = RegExp(
    r'(lib/[\w/]+\.dart:\d+(?::\d+)?)',
  ).firstMatch(text.replaceAll(r'\', '/'))?.group(1);
  return LayoutIssue(
    scenario: scenario,
    viewport: v,
    key: _normalise(summary),
    location: location,
    detail: text,
  );
}

String _normalise(String s) => s
    .replaceAll(RegExp(r'\d+(\.\d+)?'), 'N')
    .replaceAll(RegExp(r'#[0-9a-f]{5}'), '');

bool _isControl(Widget w) =>
    w is DesktopIconButton ||
    w is DesktopPillButton ||
    w is DesktopSegmented ||
    w is DesktopDropdown ||
    w is DesktopMenuButton ||
    w is Switch ||
    w is Checkbox ||
    w is TextField ||
    w is IconButton;

String _describe(Widget w) {
  final what = switch (w) {
    DesktopIconButton(:final tooltip, :final icon) =>
      tooltip ?? 'icon ${icon.codePoint.toRadixString(16)}',
    DesktopPillButton(:final label) => label,
    DesktopDropdown(:final valueLabel) => valueLabel,
    DesktopMenuButton(:final valueLabel) => valueLabel,
    TextField(:final decoration) => decoration?.hintText ?? '',
    IconButton(:final tooltip) => tooltip ?? '',
    _ => '',
  };
  return '${w.runtimeType}${what.isEmpty ? '' : ' "$what"'}';
}

/// Skips controls merely scrolled out of view: that is not a layout bug.
List<LayoutIssue> unreachableControls(
  WidgetTester tester, {
  required String scenario,
  required WindowSize viewport,
}) {
  final issues = <LayoutIssue>[];
  final window = Offset.zero & viewport.logical;
  final elements = find.byWidgetPredicate(_isControl).evaluate();

  for (final element in elements) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) continue;
    if (box.size.isEmpty) continue;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );

    var visible = window;
    var horizontallyScrolled = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is Scrollable) {
        final s = ancestor.widget as Scrollable;
        final r = ancestor.renderObject;
        if (r is RenderBox && r.hasSize) {
          visible = visible.intersect(
            MatrixUtils.transformRect(
              r.getTransformTo(null),
              Offset.zero & r.size,
            ),
          );
        }
        if (axisDirectionToAxis(s.axisDirection) == Axis.horizontal) {
          horizontallyScrolled = true;
        }
      }
      return true;
    });
    if (!visible.contains(rect.center)) continue;

    final what = _describe(element.widget);
    if (!horizontallyScrolled &&
        (rect.left < window.left - 0.5 || rect.right > window.right + 0.5)) {
      issues.add(
        LayoutIssue(
          scenario: scenario,
          viewport: viewport,
          key: '$what extends past the window edge',
          location: null,
          detail: 'rect $rect, window $window',
        ),
      );
      continue;
    }

    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      rect.center,
      tester.view.viewId,
    );
    final own = <Object>{};
    void collect(Element e) {
      final r = e.renderObject;
      if (r != null) own.add(r);
      e.visitChildren(collect);
    }

    collect(element);
    final hit = result.path.any((e) => own.contains(e.target));
    if (hit) continue;
    final top = result.path.isEmpty
        ? 'nothing'
        : result.path.first.target.toString();
    final covering = _coveringWidget(result);
    issues.add(
      LayoutIssue(
        scenario: scenario,
        viewport: viewport,
        key: '$what is covered at its centre by $covering',
        location: null,
        detail: 'rect $rect; topmost hit: $top',
      ),
    );
  }
  return issues;
}

String _coveringWidget(HitTestResult result) {
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderObject) {
      final creator = target.debugCreator;
      if (creator is DebugCreator) {
        final chain = creator.element.debugGetCreatorChain(4);
        return chain.split(' ← ').take(3).join(' ← ');
      }
    }
  }
  return 'something';
}
