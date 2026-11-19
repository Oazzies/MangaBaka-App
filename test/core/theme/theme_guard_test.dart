import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A colour literal is invisible to every theme but the one it was picked on.
void main() {
  const allowed = {
    // The picker renders the colour space itself (white→hue, clear→black).
    'lib/features/appearance/widgets/mb_color_picker.dart',
    'lib/features/appearance/widgets/color_picker_controls.dart',
  };

  final banned = <String, RegExp>{
    'colour literal': RegExp(r'\bColor\(0x'),
    'Colors.white/black': RegExp(r'\bColors\.(white|black)\w*'),
    'Color.fromARGB/RGBO': RegExp(r'\bColor\.from(ARGB|RGBO)\('),
  };

  test('no hardcoded colours outside lib/core/theme', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/core/theme/') || allowed.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final e in banned.entries) {
          if (e.value.hasMatch(line)) {
            offenders.add('$path:${i + 1} (${e.key}): ${line.trim()}');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use context.colors.<token> (or FixedColors for content over '
          'imagery). Offenders:\n${offenders.join('\n')}',
    );
  });
}
