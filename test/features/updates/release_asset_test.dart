import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

void main() {
  group('ReleaseAsset.sha256', () {
    const hex =
        'ab3f0f1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f90';

    ReleaseAsset parse(Object? digest) => ReleaseAsset.fromJson({
          'name': 'MangaBaka-windows-setup.exe',
          'browser_download_url': 'https://example.com/a.exe',
          'size': 10,
          'digest': digest,
        });

    test('reads a GitHub sha256 digest', () {
      expect(parse('sha256:${hex.toUpperCase()}').sha256, hex);
    });

    test('is null when absent, malformed or another algorithm', () {
      expect(parse(null).sha256, isNull);
      expect(parse('sha256:1234').sha256, isNull);
      expect(parse('sha512:$hex').sha256, isNull);
      expect(parse(42).sha256, isNull);
    });
  });
}
