import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SyncProgressOverlay extends StatelessWidget {
  const SyncProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryService = getIt<LibraryService>();
    final isDesktop = DesktopLayout.isDesktopPlatform;

    return ValueListenableBuilder<LibrarySyncStatus>(
      valueListenable: libraryService.syncStatus,
      builder: (context, status, child) {
        if (status.currentEntries == 0 && status.error == null) {
          return const SizedBox.shrink();
        }

        return Padding(
              padding: isDesktop
                  ? const EdgeInsets.fromLTRB(0, 0, 28, 28)
                  : const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Align(
                alignment: isDesktop
                    ? Alignment.bottomRight
                    : Alignment.bottomCenter,
                child: _buildCard(
                  context,
                  libraryService,
                  status,
                  isDesktop: isDesktop,
                ),
              ),
            )
            .animate(target: status.isSyncing ? 1 : 0)
            .slideY(
              begin: 1,
              end: 0,
              curve: Curves.easeOutBack,
              duration: 400.ms,
            )
            .fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    LibraryService libraryService,
    LibrarySyncStatus status, {
    required bool isDesktop,
  }) {
    final hasError = status.error != null;
    final l10n = LocalizationService();

    return Container(
      constraints: isDesktop ? const BoxConstraints(maxWidth: 380) : null,
      width: isDesktop ? null : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(
          isDesktop ? 10 : AppConstants.largeRadius,
        ),
        border: Border.all(color: context.colors.border),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: context.colors.shadowAt(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : context.colors.softShadow,
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
                          color: context.colors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            hasError ? Icons.warning_amber_rounded : Icons.sync,
                            color: hasError
                                ? context.colors.error
                                : context.colors.accent,
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
                              context.colors.accent,
                            ),
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
                              : l10n
                                    .translate('entries_synced')
                                    .replaceAll(
                                      '{count}',
                                      status.currentEntries.toString(),
                                    ),
                          style: AppTypography.sans(
                            color: hasError
                                ? context.colors.error
                                : context.colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasError
                              ? (status.error ??
                                    l10n.translate('an_error_occurred'))
                              : l10n.translate('keep_app_open'),
                          style: AppTypography.sans(
                            color: hasError
                                ? context.colors.error.withValues(alpha: 0.85)
                                : context.colors.textMuted,
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
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppConstants.pillRadius,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.translate('stop'),
                        style: AppTypography.sans(
                          color: context.colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.close, color: context.colors.error, size: 14),
                    ],
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: context.colors.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
        ],
      ),
    );
  }
}
