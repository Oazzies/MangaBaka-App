import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appVersion is read from the bundled pubspec', () async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final expected = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+\d+',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    expect(expected, isNotNull, reason: 'pubspec.yaml has no x.y.z+n version');

    await AppConstants.loadAppVersion();

    expect(AppConstants.appVersion, expected);
    expect(AppConstants.userAgent, startsWith('MangaBaka/$expected '));
  });

  test('parsePubspecVersion drops the build number', () {
    expect(
      AppConstants.parsePubspecVersion('name: app\nversion: 1.2.3+45\n'),
      '1.2.3',
    );
    expect(AppConstants.parsePubspecVersion('name: app\n'), isNull);
  });
}
