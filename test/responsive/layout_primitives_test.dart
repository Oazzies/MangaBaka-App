import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/fit_or_else.dart';
import 'package:mangabaka_app/desktop/shell/active_page_stack.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';

/// The building blocks the resize rules (lib/desktop/RESPONSIVE.md) rely on.
void main() {
  Widget boxOf(double width, Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, height: 200, child: child),
    ),
  );

  group('DerivedLayoutBuilder', () {
    testWidgets('rebuilds only when the derived value changes', (tester) async {
      var builds = 0;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(300, 200);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DerivedLayoutBuilder<bool>(
            derive: (c) => c.maxWidth >= 500,
            builder: (context, wide) {
              builds++;
              return Text('$wide');
            },
          ),
        ),
      );
      expect(builds, 1);

      // A drag-resize within the band: every frame lays out, none rebuilds.
      for (var w = 301.0; w < 500; w += 7) {
        tester.view.physicalSize = Size(w, 200);
        await tester.pump();
      }
      expect(builds, 1);

      // Crossing the threshold rebuilds once.
      tester.view.physicalSize = const Size(640, 200);
      await tester.pump();
      expect(builds, 2);
      expect(find.text('true'), findsOneWidget);
    });

    testWidgets('reacts when a dependency its builder read changes', (
      tester,
    ) async {
      Widget withColor(Color color) => Theme(
        data: ThemeData(primaryColor: color),
        child: boxOf(
          400,
          DerivedLayoutBuilder<int>(
            derive: (c) => c.maxWidth ~/ 1000,
            builder: (context, _) =>
                Text('${Theme.of(context).primaryColor.toARGB32()}'),
          ),
        ),
      );

      const first = Color(0xFF112233);
      const second = Color(0xFF445566);
      await tester.pumpWidget(withColor(first));
      expect(find.text('${first.toARGB32()}'), findsOneWidget);
      await tester.pumpWidget(withColor(second));
      expect(find.text('${second.toARGB32()}'), findsOneWidget);
    });
  });

  group('ActivePageStack', () {
    Widget stack(int index, List<Widget> pages) => Directionality(
      textDirection: TextDirection.ltr,
      child: ActivePageStack(index: index, children: pages),
    );

    testWidgets('lays out only the active page, keeping the others alive', (
      tester,
    ) async {
      final keys = [GlobalKey<_CounterState>(), GlobalKey<_CounterState>()];
      final pages = [
        _Counter(key: keys[0], label: 'a'),
        _Counter(key: keys[1], label: 'b'),
      ];

      await tester.pumpWidget(stack(0, pages));
      keys[0].currentState!.increment();
      await tester.pump();
      expect(find.text('a1'), findsOneWidget);
      // The hidden page is offstage to finders and never laid out.
      expect(find.text('b0'), findsNothing);
      final hidden = keys[1].currentContext!.findRenderObject()! as RenderBox;
      expect(hidden.hasSize, isFalse);

      await tester.pumpWidget(stack(1, pages));
      expect(find.text('b0'), findsOneWidget);
      final shownSize = hidden.size;

      // Back to the first page: its state survived being hidden.
      await tester.pumpWidget(stack(0, pages));
      expect(find.text('a1'), findsOneWidget);

      // A resize doesn't touch the hidden page's layout.
      tester.view.physicalSize = const Size(1234, 777);
      addTearDown(tester.view.reset);
      await tester.pump();
      expect(hidden.size, shownSize);
    });

    testWidgets('hidden pages see the window as it was', (tester) async {
      final sizes = <String, Size>{};
      Widget page(String id) => Builder(
        builder: (context) {
          sizes[id] = MediaQuery.sizeOf(context);
          return const SizedBox.expand();
        },
      );
      final pages = [page('a'), page('b')];

      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery.fromView(view: tester.view, child: stack(1, pages)),
      );
      await tester.pumpWidget(
        MediaQuery.fromView(view: tester.view, child: stack(0, pages)),
      );
      sizes.clear();

      tester.view.physicalSize = const Size(1500, 800);
      await tester.pump();
      expect(sizes.keys, ['a'], reason: 'only the active page rebuilds');
      expect(sizes['a'], const Size(1500, 800));
    });

    testWidgets('hidden pages have their tickers paused', (tester) async {
      final pages = [const SizedBox(), const _Ticking()];
      await tester.pumpWidget(stack(0, pages));
      expect(
        TickerMode.valuesOf(
          tester.element(find.byType(_Ticking, skipOffstage: false)),
        ).enabled,
        isFalse,
      );
      await tester.pumpWidget(stack(1, pages));
      expect(
        TickerMode.valuesOf(tester.element(find.byType(_Ticking))).enabled,
        isTrue,
      );
    });
  });

  group('FitOrElse', () {
    Widget at(double width) => boxOf(
      width,
      Align(
        alignment: Alignment.topLeft,
        child: FitOrElse(
          fallback: const SizedBox(width: 40, height: 20, child: Text('small')),
          child: const SizedBox(width: 300, height: 20, child: Text('wide')),
        ),
      ),
    );

    testWidgets('shows the child while it fits, the fallback when not', (
      tester,
    ) async {
      await tester.pumpWidget(at(400));
      expect(find.text('wide'), findsOneWidget);
      expect(find.text('small'), findsNothing);

      await tester.pumpWidget(at(299));
      expect(find.text('small'), findsOneWidget);
      expect(find.text('wide'), findsNothing);
      // Only what's shown takes the pointer.
      expect(tester.getSize(find.byType(FitOrElse)), const Size(40, 20));

      await tester.pumpWidget(at(300));
      expect(find.text('wide'), findsOneWidget);
    });
  });

  group('BesideOrBelow', () {
    Widget at(double width) => boxOf(
      width,
      BesideOrBelow(
        minBodyWidth: 200,
        body: const Text('body'),
        trailing: const SizedBox(width: 150, height: 30, child: Text('ctl')),
      ),
    );

    testWidgets('trailing beside while the body keeps its width, else below', (
      tester,
    ) async {
      await tester.pumpWidget(at(500));
      final besideTop = tester.getTopLeft(find.text('ctl'));
      expect(besideTop.dx, 500 - 150);

      // 200 body + 16 gap + 150 control = 366: one pixel less moves it.
      await tester.pumpWidget(at(365));
      final below = tester.getTopLeft(find.text('ctl'));
      expect(below.dx, 0);
      expect(below.dy, greaterThan(besideTop.dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('CarouselGeometry', () {
    test('stretched items fill the row exactly, edge to edge', () {
      for (var width = 150.0; width < 3000; width += 3.7) {
        final g = CarouselGeometry.resolve(
          width,
          targetWidth: 156,
          spacing: 18,
          stretch: true,
        );
        final used = g.count * g.itemWidth + (g.count - 1) * 18;
        expect(used, closeTo(width, 1e-6), reason: 'at $width');
        expect(g.rowWidth, width);
        // Never stretched so far that another item would have fitted.
        expect(g.itemWidth, lessThan(156 + 18 + 156 / g.count + 1e-6));
        // Stretched, never squeezed — unless even one item doesn't fit.
        if (width >= 156) {
          expect(g.itemWidth, greaterThanOrEqualTo(156 - 1e-6));
        } else {
          expect(g.itemWidth, width);
        }
      }
    });

    test('fixed items narrow the row to a whole number of them', () {
      for (var width = 150.0; width < 3000; width += 3.7) {
        final g = CarouselGeometry.resolve(
          width,
          targetWidth: 130,
          spacing: 18,
          stretch: false,
        );
        expect(g.itemWidth, 130);
        expect(g.rowWidth, lessThanOrEqualTo(width));
        expect(g.rowWidth, closeTo(g.count * 148 - 18, 1e-6));
      }
    });
  });

  group('WidgetUtils.decodeWidth', () {
    testWidgets('moves in 64px steps, so a resize rarely re-decodes', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      tester.view.devicePixelRatio = 1.25;
      addTearDown(tester.view.reset);
      await tester.pump();

      final widths = {
        for (var w = 150.0; w <= 250; w += 0.5)
          WidgetUtils.decodeWidth(context, w),
      };
      // 100 logical px at 1.25x is 125 physical: two or three steps, not 200.
      expect(widths.length, lessThanOrEqualTo(3));
      for (final w in widths) {
        expect(w % 64, 0);
      }
      // Never below what the display needs.
      expect(WidgetUtils.decodeWidth(context, 200), greaterThanOrEqualTo(250));
    });
  });
}

class _Counter extends StatefulWidget {
  final String label;
  const _Counter({super.key, required this.label});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  void increment() => setState(() => count++);

  @override
  Widget build(BuildContext context) => Text('${widget.label}$count');
}

class _Ticking extends StatelessWidget {
  const _Ticking();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
