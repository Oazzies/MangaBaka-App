import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';

import 'viewports.dart';

/// One problem the sweep found, with the window it first appeared at.
class LayoutIssue {
  final String scenario;
  final WindowSize viewport;

  /// What went wrong, with anything size-specific (overflow amounts,
  /// constraint values) normalised so repeats of one bug group together.
  final String key;

  /// Where in `lib/` it came from, when the error says.
  final String? location;

  /// The full error text, for the first occurrence.
  final String detail;

  LayoutIssue({
    required this.scenario,
    required this.viewport,
    required this.key,
    required this.location,
    required this.detail,
  });
}

/// Collects every [LayoutIssue] of a run and renders them as one report.
///
/// [attach] routes framework errors here from then on — call it before the
/// app is first pumped, so errors while a page loads are caught with their
/// full detail like the rest. [scenario] and [viewport] label whatever is
/// recorded next.
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

  /// Fails the test with every distinct issue found, grouped, instead of
  /// stopping at the first — a responsive bug usually shows up at a whole
  /// band of sizes, and the band is what makes it diagnosable.
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

/// Applies [v] to the test window.
void applyViewport(WidgetTester tester, WindowSize v) {
  tester.view.devicePixelRatio = v.dpr;
  tester.view.physicalSize = v.physical;
  tester.platformDispatcher.textScaleFactorTestValue = v.textScale;
}

/// Restores the test window to its defaults.
void resetViewport(WidgetTester tester) {
  tester.view.reset();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}

/// Resizes the live app through [viewports] in order — the way a user drags
/// a window, not a fresh start at each size — recording every framework
/// error (overflow, unbounded constraints, exceptions in build/layout/paint)
/// and every on-screen control that can't be clicked. [log] must be
/// attached.
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
    // Two frames: the resize itself, then whatever it scheduled after
    // layout (scroll realignment, post-frame measurement).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    if (checkControls) {
      // Let transitions a resize started (a breakpoint flipping a layout,
      // the sidebar sliding) finish first: a control covered mid-animation
      // is not one the user is stuck with.
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

/// The interactive widgets whose reachability is checked.
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

/// Every control on screen that a pointer can't reach: cut off by the window
/// edge, or covered at its centre by something else (the window buttons, an
/// overlay, a sibling that grew over it).
///
/// Controls scrolled out of their scroll view, or outside the window
/// vertically on a page that scrolls, are skipped — that's not a layout bug.
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

    // The area the control can legitimately be shown in: the window,
    // narrowed by every scroll view around it.
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
    // Reached if the hit lands on the control or anything inside it.
    final own = <Object>{};
    void collect(Element e) {
      final r = e.renderObject;
      if (r != null) own.add(r);
      e.visitChildren(collect);
    }

    collect(element);
    final hit = result.path.any((e) => own.contains(e.target));
    if (!hit) {
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
  }
  return issues;
}

/// A readable name for whatever took the hit instead: the nearest widget of
/// the topmost render object hit.
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
