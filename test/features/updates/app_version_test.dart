import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

void main() {
  group('AppVersion.parse', () {
    test('parses a pre-release with a v prefix and build metadata', () {
      final v = AppVersion.parse('v0.1.0-pre-release-8+8');
      expect(v.major, 0);
      expect(v.minor, 1);
      expect(v.patch, 0);
      expect(v.preRelease, 8);
    });

    test('parses a stable version as having no pre-release', () {
      final v = AppVersion.parse('1.2.3');
      expect(v.preRelease, isNull);
    });

    test('parses the new tag format v0.2.2', () {
      final v = AppVersion.parse('v0.2.2');
      expect(v.major, 0);
      expect(v.minor, 2);
      expect(v.patch, 2);
      expect(v.preRelease, isNull);
    });
  });

  group('AppVersion comparison', () {
    AppVersion p(String s) => AppVersion.parse(s);

    test('higher pre-release number is newer', () {
      expect(p('0.1.0-pre-release-9').isNewerThan(p('0.1.0-pre-release-8')),
          isTrue);
      expect(p('0.1.0-pre-release-8').isNewerThan(p('0.1.0-pre-release-9')),
          isFalse);
    });

    test('equal versions are not newer', () {
      expect(p('v0.1.0-pre-release-8').isNewerThan(p('0.1.0-pre-release-8')),
          isFalse);
    });

    test('stable release is newer than a pre-release of the same base', () {
      expect(p('0.1.0').isNewerThan(p('0.1.0-pre-release-8')), isTrue);
      expect(p('0.1.0-pre-release-8').isNewerThan(p('0.1.0')), isFalse);
    });

    test('numeric components take priority over pre-release', () {
      expect(p('0.2.0-pre-release-1').isNewerThan(p('0.1.0-pre-release-99')),
          isTrue);
      expect(p('1.0.0').isNewerThan(p('0.9.9')), isTrue);
    });

    test('new tag format v0.2.2 comparison', () {
      expect(p('v0.2.2').isNewerThan(p('v0.2.1')), isTrue);
      expect(p('v0.2.2').isNewerThan(p('0.1.0-pre-release-10')), isTrue);
      expect(p('v0.2.2').isNewerThan(p('v0.2.2')), isFalse);
    });
  });
}
