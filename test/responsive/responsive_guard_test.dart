import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the rules in lib/desktop/RESPONSIVE.md that can be read off the
/// source: the patterns that made resizing the desktop app lag, or overflow.
///
/// A justified exception carries `// responsive-ok: <why>` on the offending
/// line or in the comment block right above it.
void main() {
  // Shared widgets desktop pages render inside resizing lists and grids.
  const sharedRenderedOnDesktop = [
    'lib/core/widgets/dynamic_row_height_grid.dart',
    'lib/features/series/widgets/entry_list_item.dart',
    'lib/features/series/widgets/entry_list_item_layouts.dart',
    'lib/features/series/widgets/entry_progress_overlay.dart',
    'lib/features/library/widgets/library_grid_list.dart',
    'lib/features/browse/widgets/results/browse_content.dart',
    'lib/features/browse/widgets/results/browse_results_list.dart',
    'lib/features/browse/widgets/mix/mix_results_sliver.dart',
    'lib/features/profile/widgets/settings/list_style_live_preview.dart',
    'lib/features/profile/widgets/settings/list_scope_tab_selector.dart',
  ];

  final files = [
    ...Directory('lib/desktop')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path.replaceAll(r'\', '/')),
    ...sharedRenderedOnDesktop,
  ]..sort();

  final lineRules = <String, (RegExp, String)>{
    'IndexedStack/Offstage': (
      RegExp(r'\b(IndexedStack|Offstage)\('),
      'lays out hidden children every frame — use ActivePageStack (rule 1)',
    ),
    'LayoutBuilder': (
      RegExp(r'\b(LayoutBuilder|SliverLayoutBuilder)\('),
      'rebuilds its subtree on every frame of a resize — use '
          'DerivedLayoutBuilder for a decision, or layout-time geometry '
          '(rule 2, 3)',
    ),
    'MediaQuery.of': (
      RegExp(r'MediaQuery\.of\('),
      'depends on every aspect of the window — use sizeOf/textScalerOf/'
          'devicePixelRatioOf (rule 4)',
    ),
    'live decode width': (
      RegExp(
        r'memCacheWidth:(?!\s*WidgetUtils\.decodeWidth)\s*[^,\n]*[wW]idth',
      ),
      're-decodes the image whenever the width moves — use '
          'WidgetUtils.decodeWidth or a fixed width (rule 6)',
    ),
    'runtime blur': (
      RegExp(r'\b(ImageFiltered|BackdropFilter)\('),
      're-rasterised every frame the area resizes — downsample instead '
          '(rule 6)',
    ),
    'intrinsic layout': (
      RegExp(r'\b(IntrinsicHeight|IntrinsicWidth)\('),
      'lays its subtree out twice (rule 7)',
    ),
    'shrinkWrap': (
      RegExp(r'shrinkWrap:\s*true'),
      'lays out every item of the list (rule 7)',
    ),
  };

  /// Whether line [i], or the comment block right above it (up to three code
  /// lines up, to reach past a line break in the call), carries the marker.
  bool excused(List<String> lines, int i) {
    var codeLines = 0;
    for (var j = i; j >= 0; j--) {
      final line = lines[j];
      if (line.contains('responsive-ok:')) return true;
      final isComment = line.trimLeft().startsWith('//');
      if (!isComment && j != i && ++codeLines > 3) break;
    }
    return false;
  }

  test('desktop code follows the resize rules', () {
    final offenders = <String>[];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      final lines = source.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.split('//').first;
        if (code.trim().isEmpty) continue;
        for (final MapEntry(key: name, value: (pattern, why))
            in lineRules.entries) {
          if (pattern.hasMatch(code) && !excused(lines, i)) {
            offenders.add('$path:${i + 1} ($name): ${line.trim()}\n    → $why');
          }
        }
      }

      // Rule 5: an AnimatedContainer animating a size that isn't a constant.
      for (final match in RegExp(r'\bAnimatedContainer\(').allMatches(source)) {
        final args = _topLevelArguments(source, match.end);
        for (final MapEntry(key: name, value: value) in args.entries) {
          if (!const {'width', 'height', 'constraints'}.contains(name)) {
            continue;
          }
          if (RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) continue;
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          if (excused(lines, line)) continue;
          offenders.add(
            '$path:${line + 1} (animated size): AnimatedContainer($name: '
            '$value)\n    → animates on every frame the size follows the '
            'window — size it with a SizedBox outside (rule 5)',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'See lib/desktop/RESPONSIVE.md. Mark a justified exception with '
          '"// responsive-ok: <why>".\n${offenders.join('\n')}',
    );
  });
}

/// The top-level named arguments of the call whose argument list starts at
/// [start] (just after its opening parenthesis), as name → source text.
Map<String, String> _topLevelArguments(String source, int start) {
  final args = <String, String>{};
  var depth = 1;
  var argStart = start;
  for (var i = start; i < source.length && depth > 0; i++) {
    final c = source[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if ((c == ',' && depth == 1) || depth == 0) {
      final arg = source.substring(argStart, i).trim();
      final colon = arg.indexOf(':');
      if (colon > 0) {
        final name = arg.substring(0, colon).trim();
        if (RegExp(r'^\w+$').hasMatch(name)) {
          args[name] = arg.substring(colon + 1).trim();
        }
      }
      argStart = i + 1;
    }
  }
  return args;
}
