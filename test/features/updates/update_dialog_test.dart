import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/features/updates/widgets/update_dialog.dart';

class _FakeUpdateService extends UpdateService {
  _FakeUpdateService({required this.asset, this.downloadError});

  final ReleaseAsset? asset;
  final Object? downloadError;
  int downloads = 0;
  int installs = 0;

  @override
  bool get supportsInAppUpdate => true;

  @override
  Future<ReleaseAsset?> selectAssetForPlatform(AppRelease release) async =>
      asset;

  @override
  Future<File> downloadAsset(
    ReleaseAsset asset, {
    void Function(double progress)? onProgress,
  }) async {
    downloads++;
    if (downloadError != null) throw downloadError!;
    return File('unused');
  }

  @override
  Future<void> installDownloaded(File file) async => installs++;
}

const _release = AppRelease(
  tagName: 'v9.9.9',
  name: 'v9.9.9',
  body: 'Notes',
  htmlUrl: 'https://github.com/example/repo/releases/tag/v9.9.9',
  draft: false,
  prerelease: false,
  assets: [],
);

const _hex =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

ReleaseAsset _asset({String? sha}) => ReleaseAsset(
      name: 'android-mangabaka-app-v9.9.9-arm64-v8a.apk',
      downloadUrl: 'https://example.test/app.apk',
      size: 1,
      sha256: sha,
    );

void main() {
  late _FakeUpdateService service;

  Future<void> openDialog(WidgetTester tester, _FakeUpdateService svc) async {
    service = svc;
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<UpdateService>(svc);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(ThemePresets.fallback.dark!, showTooltips: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => UpdateDialog.show(context, _release),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  tearDown(() async => resetServiceLocator());

  testWidgets('an asset without a checksum is never downloaded; the dialog '
      'hands off to the release page', (tester) async {
    await openDialog(tester, _FakeUpdateService(asset: _asset()));

    await tester.tap(find.text('Update now'));
    // Opening the release page goes through a real platform channel, whose
    // (unhandled) reply only arrives outside the fake-async zone.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(service.downloads, 0);
    expect(service.installs, 0);
    expect(find.byType(UpdateDialog), findsNothing);
  });

  testWidgets('a verified asset is downloaded and installed', (tester) async {
    await openDialog(tester, _FakeUpdateService(asset: _asset(sha: _hex)));

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();

    expect(service.downloads, 1);
    expect(service.installs, 1);
  });

  testWidgets('a failed integrity check is shown with a retry', (tester) async {
    await openDialog(
      tester,
      _FakeUpdateService(
        asset: _asset(sha: _hex),
        downloadError: UpdateIntegrityException(),
      ),
    );

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();

    expect(service.installs, 0);
    expect(find.textContaining('Update failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
