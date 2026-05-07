import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_sync_status.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bakahyou/features/navigation/screens/main_screen.dart';

class SyncProgressOverlay extends StatelessWidget {
  const SyncProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryService = getIt<LibraryService>();

    return ValueListenableBuilder<LibrarySyncStatus>(
      valueListenable: libraryService.syncStatus,
      builder: (context, status, child) {
        if (!status.isSyncing && status.currentEntries == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _buildCard(context, status),
          ),
        )
            .animate(target: status.isSyncing ? 1 : 0)
            .slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildCard(BuildContext context, LibrarySyncStatus status) {
    final hasError = status.error != null;
    final l10n = LocalizationService();

    return GestureDetector(
      onTap: () => MainScreen.setTabIndex(1), // Library is index 1
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon / spinner
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      hasError ? Icons.warning_amber_rounded : Icons.sync,
                      color: hasError
                          ? AppConstants.errorColor
                          : AppConstants.accentColor,
                      size: 20,
                    ),
                  ),
                ),
                if (!hasError && status.isSyncing)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.accentColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError
                        ? l10n.translate('sync_interrupted')
                        : l10n.translate('entries_synced').replaceAll('{count}', status.currentEntries.toString()),
                    style: TextStyle(
                      color: hasError
                          ? AppConstants.errorColor
                          : AppConstants.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasError
                        ? (status.error ?? l10n.translate('an_error_occurred'))
                        : l10n.translate('keep_app_open'),
                    style: TextStyle(
                      color: hasError
                          ? AppConstants.errorColor.withValues(alpha: 0.85)
                          : AppConstants.textMutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppConstants.textMutedColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
