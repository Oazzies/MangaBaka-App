import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/widgets/design/github_logo.dart';

void main() {
  group('parseSvgPath', () {
    test('handles relative and absolute lines and closes the subpath', () {
      final path = parseSvgPath('M2 2 l4 0 v4 H2 Z');
      expect(path.getBounds(), const Rect.fromLTRB(2, 2, 6, 6));
      expect(path.contains(const Offset(4, 4)), isTrue);
      expect(path.contains(const Offset(7, 4)), isFalse);
    });

    test('reads compact numbers such as ".5.25" and "-.5"', () {
      final path = parseSvgPath('M0 0h.5.25v-.5z');
      expect(path.getBounds().right, closeTo(0.75, 1e-9));
    });

    test('draws an arc through its end point', () {
      // A half circle of radius 4 from (0,4) to (8,4), sweeping over the top.
      final path = parseSvgPath('M0 4a4 4 0 0 1 8 0Z');
      expect(path.getBounds().top, closeTo(0, 1e-6));
      expect(path.contains(const Offset(4, 2)), isTrue);
    });
  });

  group('GithubLogo mark', () {
    final mark = parseSvgPath(
      'M8 0c4.42 0 8 3.58 8 8a8.013 8.013 0 0 1-5.45 7.59c-.4.08-.55-.17-.55-.38 '
      '0-.27.01-1.13.01-2.2 0-.75-.25-1.23-.54-1.48 1.78-.2 3.65-.88 3.65-3.95 '
      '0-.88-.31-1.59-.82-2.15.08-.2.36-1.02-.08-2.12 0 0-.67-.22-2.2.82-.64-.18'
      '-1.32-.27-2-.27-.68 0-1.36.09-2 .27-1.53-1.03-2.2-.82-2.2-.82-.44 1.1-.16 '
      '1.92-.08 2.12-.51.56-.82 1.28-.82 2.15 0 3.06 1.86 3.75 3.64 3.95-.23.2-.44'
      '.55-.51 1.07-.46.21-1.61.55-2.33-.66-.15-.24-.6-.83-1.23-.82-.67.01-.27.38'
      '.01.53.34.19.73.9.82 1.13.16.45.68 1.31 2.69.94 0 .67.01 1.3.01 1.49 0 .21'
      '-.15.45-.55.38A7.995 7.995 0 0 1 0 8c0-4.42 3.58-8 8-8Z',
    );

    test('stays inside its 16x16 box', () {
      final b = mark.getBounds();
      expect(b.left, greaterThanOrEqualTo(-0.01));
      expect(b.top, greaterThanOrEqualTo(-0.01));
      expect(b.right, lessThanOrEqualTo(16.01));
      expect(b.bottom, lessThanOrEqualTo(16.01));
      expect(b.width, closeTo(16, 0.05));
    });

    test('is a filled rim around a hollow cat head', () {
      expect(mark.contains(const Offset(1, 8)), isTrue, reason: 'left rim');
      expect(mark.contains(const Offset(15, 8)), isTrue, reason: 'right rim');
      expect(mark.contains(const Offset(8, 7)), isFalse, reason: 'head');
    });
  });

  testWidgets('renders at the requested size', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: GithubLogo(size: 40, color: Colors.white)),
      ),
    );
    expect(tester.getSize(find.byType(GithubLogo)), const Size(40, 40));
  });
}
