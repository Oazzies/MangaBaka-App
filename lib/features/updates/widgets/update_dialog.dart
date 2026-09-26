import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/updates/models/app_release.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

/// Dialog shown when a newer GitHub release is detected. Title is the release
/// name, body is the release description, with "Later" and "Update now"
/// actions. "Later" just closes it (no state stored), so it reappears next
/// launch while the installed version is still behind.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.release});

  final AppRelease release;

  static Future<void> show(BuildContext context, AppRelease release) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(release: release),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _Phase { idle, downloading, installing, error }

class _UpdateDialogState extends State<UpdateDialog> {
  static final _logger = LoggingService.logger;
  final UpdateService _service = getIt<UpdateService>();

  _Phase _phase = _Phase.idle;
  double _progress = 0;
  String? _errorMessage;

  bool get _busy => _phase == _Phase.downloading || _phase == _Phase.installing;

  Future<void> _onUpdateNow() async {
    // Platforms that can't self-install just open the release page.
    if (!_service.supportsInAppUpdate) {
      await _openReleasePage();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final asset = await _service.selectAssetForPlatform(widget.release);
      // Without a published checksum the installer cannot be verified, so
      // it is not run from here; the release page lets the user decide.
      if (asset == null || asset.sha256 == null) {
        _logger.warning(
          asset == null
              ? 'No matching update asset for platform; opening release page.'
              : 'Update asset has no published checksum; opening release page.',
        );
        await _openReleasePage();
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final file = await _service.downloadAsset(
        asset,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (!mounted) return;
      setState(() => _phase = _Phase.installing);

      // On Windows this quits the app, so execution may not return here.
      await _service.installDownloaded(file);

      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      _logger.severe('Update failed: $e', e, st);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openReleasePage() async {
    final url = widget.release.htmlUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _logger.warning('Failed to open release page: $e');
    }
  }

  String get _updateButtonLabel {
    if (_phase == _Phase.installing) {
      return Platform.isWindows ? 'Launching installer…' : 'Installing…';
    }
    if (_phase == _Phase.downloading) {
      return 'Downloading ${(_progress * 100).toStringAsFixed(0)}%';
    }
    if (_phase == _Phase.error) return 'Retry';
    return _service.supportsInAppUpdate ? 'Update now' : 'Open download';
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;

    return PopScope(
      // Block back-dismissal while downloading/installing.
      canPop: !_busy,
      child: AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: context.colors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                release.displayName,
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version (${release.tagName}) is available. '
                'You have ${AppConstants.appVersion}.',
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Text(
                      release.body.trim().isEmpty
                          ? 'No release notes provided.'
                          : release.body.trim(),
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (_phase == _Phase.downloading) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress,
                    minHeight: 6,
                    backgroundColor: context.colors.surfaceRaised,
                    color: context.colors.accent,
                  ),
                ),
              ],
              if (_phase == _Phase.installing) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    MbSpinner(
                      size: 16,
                      strokeWidth: 2,
                      color: context.colors.accent,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        Platform.isWindows
                            ? 'Launching installer — the app will close.'
                            : 'Opening installer…',
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_phase == _Phase.error && _errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                      AppConstants.denseRadius,
                    ),
                    border: Border.all(
                      color: context.colors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: context.colors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Update failed. You can retry or download it '
                          'manually from the release page.',
                          style: AppTypography.sans(
                            color: context.colors.error.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Later',
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _busy ? null : _onUpdateNow,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: context.colors.onAccent,
              disabledBackgroundColor: context.colors.accent.withValues(
                alpha: 0.5,
              ),
              disabledForegroundColor: context.colors.onAccent.withValues(
                alpha: 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
            ),
            child: Text(
              _updateButtonLabel,
              style: AppTypography.sans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
