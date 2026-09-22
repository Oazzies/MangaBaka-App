import 'package:flutter/material.dart';

import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A slim bar that appears at the top of the app while the MangaBaka backend is
/// unreachable, so a screen full of "Failed to load" states reads as an outage
/// rather than a broken app. Collapses to nothing when the backend is healthy.
class BackendHealthBanner extends StatelessWidget {
  const BackendHealthBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<BackendHealthService>()) {
      return const SizedBox.shrink();
    }
    final health = getIt<BackendHealthService>();

    return ValueListenableBuilder<BackendHealthStatus>(
      valueListenable: health.status,
      builder: (context, status, _) {
        return ListenableBuilder(
          listenable: LocalizationService(),
          builder: (context, _) {
            return AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: status == BackendHealthStatus.down
                  ? _DownBar(onRetry: health.checkNow)
                  : const SizedBox(width: double.infinity),
            );
          },
        );
      },
    );
  }
}

class _DownBar extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DownBar({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final color = context.colors.warning;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          color: color.withValues(alpha: 0.14),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.translate('backend_unreachable'),
                  style: AppTypography.sans(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.translate('retry').toUpperCase(),
                  style: AppTypography.sans(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
