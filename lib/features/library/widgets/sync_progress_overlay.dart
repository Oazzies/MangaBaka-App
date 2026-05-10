import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';

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
            child: _buildCard(context, libraryService, status),
          ),
        )
            .animate(target: status.isSyncing ? 1 : 0)
            .slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 400.ms)
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildCard(BuildContext context, LibraryService libraryService, LibrarySyncStatus status) {
    final hasError = status.error != null;
    final l10n = LocalizationService();

    return Container(
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
          // Main tap area for navigation
          Expanded(
            child: GestureDetector(
              onTap: () => MainScreen.setTabIndex(1), // Library is index 1
              behavior: HitTestBehavior.opaque,
              child: Row(
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action area
          if (status.isSyncing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => libraryService.cancelSync(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConstants.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.translate('stop'),
                        style: TextStyle(
                          color: AppConstants.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.close,
                        color: AppConstants.errorColor,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: AppConstants.textMutedColor.withValues(alpha: 0.5),
              size: 20,
            ),
        ],
      ),
    );
  }
}
