import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banner.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class LibraryStatusBanners extends StatelessWidget {
  final LibrarySyncStatus status;

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
