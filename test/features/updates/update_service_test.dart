import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';

Map<String, dynamic> _releaseJson({
  String tag = 'v99.0.0',
  bool draft = false,
  bool prerelease = false,
  List<Map<String, dynamic>>? assets,
}) =>
    {
      'tag_name': tag,
      'name': 'Release $tag',
      'body': 'Changelog',
      'html_url': 'https://github.com/example/repo/releases/tag/$tag',
      'draft': draft,
      'prerelease': prerelease,
      'published_at': '2026-01-01T00:00:00Z',
      'assets': assets ?? [],
    };

http.Client _clientWith(int status, Object body) => MockClient((request) async =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'}));

void main() {
  group('UpdateService.fetchLatestRelease', () {
    test('returns release on 200', () async {
      final client = _clientWith(200, [_releaseJson()]);
      final svc = UpdateService(client: client);
      final release = await svc.fetchLatestRelease();
      expect(release, isNotNull);
      expect(release!.tagName, 'v99.0.0');
      svc.dispose();
    });

    test('skips draft releases', () async {
      final client = _clientWith(200, [
        _releaseJson(tag: 'v99.0.0', draft: true),
        _releaseJson(tag: 'v98.0.0'),
      ]);
      final svc = UpdateService(client: client);
      final release = await svc.fetchLatestRelease();
      expect(release?.tagName, 'v98.0.0');
      svc.dispose();
    });

    test('returns null on non-200', () async {
      final client = _clientWith(500, {'error': 'server error'});
      final svc = UpdateService(client: client);
      final release = await svc.fetchLatestRelease();
      expect(release, isNull);
      svc.dispose();
    });

    test('returns null on network error', () async {
      final client = MockClient((_) async => throw const SocketException('no network'));
      final svc = UpdateService(client: client);
      final release = await svc.fetchLatestRelease();
      expect(release, isNull);
      svc.dispose();
    });

    test('returns null when list is empty', () async {
      final client = _clientWith(200, <dynamic>[]);
      final svc = UpdateService(client: client);
      final release = await svc.fetchLatestRelease();
      expect(release, isNull);
      svc.dispose();
    });
  });

  group('UpdateService.checkForUpdate', () {
    test('returns release when newer than installed', () async {
      final client = _clientWith(200, [_releaseJson(tag: 'v99.0.0')]);
      final svc = UpdateService(client: client);
      final result = await svc.checkForUpdate();
      expect(result, isNotNull);
      svc.dispose();
    });

    test('returns null when same as installed', () async {
      // AppConstants.appVersion is '0.2.4', so a lower version returns null
      final client = _clientWith(200, [_releaseJson(tag: 'v0.1.0')]);
      final svc = UpdateService(client: client);
      final result = await svc.checkForUpdate();
      expect(result, isNull);
      svc.dispose();
    });
  });

  group('UpdateService.shouldPrompt', () {
    test('returns true only once per instance', () {
      final client = MockClient((_) async => throw UnimplementedError());
      final svc = UpdateService(client: client);
      expect(svc.shouldPrompt(), isTrue);
      expect(svc.shouldPrompt(), isFalse);
      expect(svc.shouldPrompt(), isFalse);
      svc.dispose();
    });
  });

  group('UpdateService.selectAssetForPlatform', () {
    AppRelease releaseWithAssets(List<Map<String, dynamic>> assets) =>
        AppRelease.fromJson(_releaseJson(tag: 'v1.0.0', assets: assets));

    test('returns null for empty asset list', () async {
      final client = MockClient((_) async => throw UnimplementedError());
      final svc = UpdateService(client: client);
      final release = releaseWithAssets([]);
      final asset = await svc.selectAssetForPlatform(release);
      expect(asset, isNull);
      svc.dispose();
    });
  });
}
