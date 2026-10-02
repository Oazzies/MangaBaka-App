import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/core/widgets/mb_toast.dart';

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
    return SyncStatusCard(
      status: status,
      isDesktop: isDesktop,
      onStop: libraryService.cancelSync,
      onTap: () => MainScreen.setTabIndex(1), // Library is index 1
    );
  }
}

/// The card the library sync shows while it runs (or after it is interrupted).
///
/// Separate from the overlay that positions it so it can be shown with sample
/// status from Developer Tools.
class SyncStatusCard extends StatelessWidget {
  final LibrarySyncStatus status;
  final bool isDesktop;
  final VoidCallback onStop;
  final VoidCallback onTap;

  const SyncStatusCard({
    super.key,
    required this.status,
    required this.isDesktop,
    required this.onStop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = status.error != null;
    final l10n = LocalizationService();
    final kind = hasError ? ToastKind.error : ToastKind.info;
    final t = ToastColors.of(colors, kind);

    // The same solid pill the snackbars use. While entries arrive it is a
    // compact progress strip — a small spinner, what has synced so far, and a
    // slim bar along the bottom; once interrupted it turns into an error pill.
    final card = MbToastCard(
      kind: kind,
      radius: isDesktop ? 14 : 16,
      maxWidth: isDesktop ? 400 : null,
      onTap: onTap,
      leading: hasError
          ? ToastBadge(
              icon: Icons.sync_problem_rounded,
              disc: t.disc,
              onDisc: t.onDisc,
            )
          : SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: MbSpinner(size: 18, strokeWidth: 2.5, color: t.ink),
              ),
            ),
      title: hasError
          ? l10n.translate('sync_interrupted')
          : l10n
                .translate('entries_synced')
                .replaceAll('{count}', status.currentEntries.toString()),
      detail: hasError
          ? (status.error ?? l10n.translate('an_error_occurred'))
          : l10n.translate('keep_app_open'),
      trailing: [
        if (status.isSyncing)
          ToastActionPill(
            label: l10n.translate('stop'),
            kind: kind,
            icon: Icons.close_rounded,
            onPressed: onStop,
          ),
      ],
      footer: status.isSyncing
          ? ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Color.lerp(t.fill, t.ink, 0.22),
                valueColor: AlwaysStoppedAnimation(t.action),
              ),
            )
          : null,
    );

    return isDesktop ? card : SizedBox(width: double.infinity, child: card);
  }
}
