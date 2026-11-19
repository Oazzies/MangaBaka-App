import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

/// Drift makes the updater miss updates or re-offer the installed one every launch.
void main() {
  test('AppConstants.appVersion matches the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(AppConstants.appVersion, match!.group(1));
  });
}
