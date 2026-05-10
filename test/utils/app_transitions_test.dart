import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/utils/transitions/app_transitions.dart';

void main() {
  group('AppTransitions', () {
    test('fade returns a Route', () {
      final route = AppTransitions.fade(Container());
      expect(route, isA<Route>());
      expect(route, isA<PageRouteBuilder>());
    });

    test('slideUp returns a Route', () {
      final route = AppTransitions.slideUp(Container());
      expect(route, isA<Route>());
    });

    test('slideRight returns a Route', () {
      final route = AppTransitions.slideRight(Container());
      expect(route, isA<Route>());
    });
  });
}
