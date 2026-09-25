import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late int downloads;
  final payload = List<int>.generate(4096, (i) => i % 251);
  final payloadSha = sha256.convert(payload).toString();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mb_update_test');
    downloads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  UpdateService serviceServing(List<int> body) => UpdateService(
        client: MockClient((_) async {
          downloads++;
          return http.Response.bytes(body, 200);
        }),
      );

  ReleaseAsset asset({String? sha}) => ReleaseAsset(
        name: 'windows-mangabaka-app-v9.9.9-setup.exe',
        downloadUrl: 'https://example.test/setup.exe',
        size: payload.length,
        sha256: sha,
      );

  test('refuses an asset without a published checksum before downloading',
      () async {
    final svc = serviceServing(payload);

    await expectLater(
      svc.downloadAsset(asset()),
      throwsA(isA<UpdateIntegrityException>()
          .having((e) => e.code, 'code', 'CHECKSUM_MISSING')),
    );
    expect(downloads, 0);
    expect(tempDir.listSync(), isEmpty);
  });

  test('returns the file when its checksum matches', () async {
    final svc = serviceServing(payload);

    final file = await svc.downloadAsset(asset(sha: payloadSha));

    expect(await file.readAsBytes(), payload);
  });

  test('deletes a file whose checksum does not match', () async {
    final tampered = [...payload]..[0] ^= 0xff;
    final svc = serviceServing(tampered);

    await expectLater(
      svc.downloadAsset(asset(sha: payloadSha)),
      throwsA(isA<UpdateIntegrityException>()
          .having((e) => e.code, 'code', 'CHECKSUM_MISMATCH')),
    );
    expect(tempDir.listSync(), isEmpty);
  });

  test('never places the file outside the temp directory', () async {
    final svc = serviceServing(payload);
    final hostile = ReleaseAsset(
      name: '../../evil.exe',
      downloadUrl: 'https://example.test/evil.exe',
      size: payload.length,
      sha256: payloadSha,
    );

    final file = await svc.downloadAsset(hostile);

    expect(file.parent.path, tempDir.path);
    expect(file.uri.pathSegments.last, 'evil.exe');
  });
}
