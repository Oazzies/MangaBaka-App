import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class DiscoveryQueueNotReadyState extends StatelessWidget {
  final LocalizationService l10n;

  const DiscoveryQueueNotReadyState({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: context.colors.accent,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('discovery_queue').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('discovery_queue_not_ready'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.translate('back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoveryQueueEmptyState extends StatelessWidget {
  final LocalizationService l10n;
  final VoidCallback onRestart;

  const DiscoveryQueueEmptyState({
    super.key,
    required this.l10n,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 64,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate('discovery_queue_empty'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoveryQueueErrorState extends StatelessWidget {
  final LocalizationService l10n;
  final String messageKey;
  final VoidCallback onRestart;

  const DiscoveryQueueErrorState({
    super.key,
    required this.l10n,
    required this.messageKey,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: context.colors.error,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.translate(messageKey),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoveryQueueCompletedState extends StatelessWidget {
  final LocalizationService l10n;
  final int reviewedCount;
  final int addedCount;
  final VoidCallback onRestart;

  const DiscoveryQueueCompletedState({
    super.key,
    required this.l10n,
    required this.reviewedCount,
    required this.addedCount,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accent.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.translate('discovery_queue_complete_title').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n
                    .translate('discovery_queue_complete_message')
                    .replaceAll('{reviewed}', '$reviewedCount')
                    .replaceAll('{added}', '$addedCount'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.translate('done')),
                  ),
                  FilledButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      l10n.translate('discovery_queue_start_another'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
