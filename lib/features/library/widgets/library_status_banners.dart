import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banner.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The banners that sit above the library list when something needs saying:
/// the server is unreachable, the last sync failed, or the local copy is
/// known to be incomplete.
///
/// At most all three can apply at once, so they stack rather than replacing
/// each other — each describes a different problem with a different remedy.
class LibraryStatusBanners extends StatelessWidget {
  final LibrarySyncStatus status;

  /// True when the local library is known to be missing entries — the initial
  /// import hit its page limit and never finished.
  final bool isIncomplete;

  final VoidCallback onRetrySync;
  final VoidCallback onDismissError;
  final VoidCallback onImportFullLibrary;

  const LibraryStatusBanners({
    super.key,
    required this.status,
    required this.isIncomplete,
    required this.onRetrySync,
    required this.onDismissError,
    required this.onImportFullLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status.isServerDown)
          LibraryStatusBanner(
            message: l10n.translate('server_unreachable_warning'),
            icon: Icons.cloud_off_rounded,
            color: context.colors.error,
            action: _action(
              label: l10n.translate('retry'),
              color: context.colors.error,
              onPressed: onRetrySync,
            ),
          ),
        // A specific sync error is only worth showing when the server is
        // otherwise reachable; during an outage the banner above already
        // explains it, and both at once is noise.
        if (!status.isServerDown && status.error != null)
          LibraryStatusBanner(
            message: l10n
                .translate('sync_failed')
                .replaceAll('{message}', status.error!),
            icon: Icons.error_outline_rounded,
            color: context.colors.error,
            onClose: onDismissError,
          ),
        if (isIncomplete)
          LibraryStatusBanner(
            message: l10n.translate('library_limit_warning'),
            icon: Icons.warning_amber_rounded,
            color: context.colors.warning,
            action: _action(
              label: l10n.translate('update'),
              color: context.colors.warning,
              onPressed: onImportFullLibrary,
            ),
          ),
      ],
    );
  }

  Widget _action({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTypography.sans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
