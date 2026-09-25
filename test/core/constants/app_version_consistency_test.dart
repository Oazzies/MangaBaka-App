import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

/// The in-app updater compares [AppConstants.appVersion] against the latest
/// GitHub release, while builds are numbered from pubspec.yaml. If the two
/// drift apart, installed builds either never see an update or are offered
/// the one they already run on every launch.
void main() {
  test('AppConstants.appVersion matches the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(AppConstants.appVersion, match!.group(1));
  });
}
