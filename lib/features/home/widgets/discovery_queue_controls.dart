import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/home/widgets/discovery_add_to_library_button.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';

export 'package:mangabaka_app/features/home/widgets/discovery_add_to_library_button.dart';

class DiscoveryQueueControlCard extends StatelessWidget {
  final LocalizationService l10n;
  final int currentIndex;
  final int totalCount;
  final double progress;
  final String selectedState;
  final List<String> states;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onStateSelected;
  final VoidCallback onSkip;
  final VoidCallback onNotInterested;

  const DiscoveryQueueControlCard({
    super.key,
    required this.l10n,
    required this.currentIndex,
    required this.totalCount,
    required this.progress,
    required this.selectedState,
    required this.states,
    required this.busy,
    required this.onAdd,
    required this.onStateSelected,
    required this.onSkip,
    required this.onNotInterested,
  });

  @override
  Widget build(BuildContext context) {
    final counter = '${currentIndex + 1} / $totalCount';
    return MbCard(
      label: l10n.translate('discovery_queue'),
      trailing: _CounterPill(counter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              color: context.colors.accent,
              backgroundColor: context.colors.surfaceRaised,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 18),
          DiscoveryAddToLibraryButton(
            selectedState: selectedState,
            states: states,
            busy: busy,
            onAdd: busy ? null : onAdd,
            onStateSelected: onStateSelected,
          ),
          const SizedBox(height: 12),
          MbSecondaryButton(
            label: l10n.translate('discovery_queue_skip'),
            icon: Icons.skip_next_rounded,
            onPressed: busy ? null : onSkip,
            expand: true,
          ),
          const SizedBox(height: 12),
          MbSecondaryButton(
            label: l10n.translate('discovery_queue_not_interested'),
            icon: Icons.thumb_down_alt_outlined,
            onPressed: busy ? null : onNotInterested,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class DiscoveryQueueControlBar extends StatelessWidget {
  final LocalizationService l10n;
  final bool isDesktop;
  final bool atBottom;
  final int currentIndex;
  final int totalCount;
  final double progress;
  final String selectedState;
  final List<String> states;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onStateSelected;
  final VoidCallback onSkip;
  final VoidCallback onNotInterested;

  const DiscoveryQueueControlBar({
    super.key,
    required this.l10n,
    required this.isDesktop,
    required this.atBottom,
    required this.currentIndex,
    required this.totalCount,
    required this.progress,
    required this.selectedState,
    required this.states,
    required this.busy,
    required this.onAdd,
    required this.onStateSelected,
    required this.onSkip,
    required this.onNotInterested,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = isDesktop ? DesktopTokens.pagePadding : 12.0;
    final counter = '${currentIndex + 1} / $totalCount';
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: atBottom
              ? Border.all(color: context.colors.border, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: context.colors.shadowAt(0.35),
              blurRadius: 16,
              offset: Offset(0, atBottom ? -6 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BesideOrBelow(
              minBodyWidth: 140,
              gap: 10,
              stackGap: 8,
              body: Text(
                l10n.translate('discovery_queue').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 14,
                ),
              ),
              trailing: _CounterPill(counter),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                color: context.colors.accent,
                backgroundColor: context.colors.surfaceRaised,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 12),
            DiscoveryAddToLibraryButton(
              selectedState: selectedState,
              states: states,
              busy: busy,
              onAdd: busy ? null : onAdd,
              onStateSelected: onStateSelected,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MbSecondaryButton(
                    label: l10n.translate('discovery_queue_skip'),
                    icon: Icons.skip_next_rounded,
                    onPressed: busy ? null : onSkip,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MbSecondaryButton(
                    label: l10n.translate('discovery_queue_not_interested'),
                    icon: Icons.thumb_down_alt_outlined,
                    onPressed: busy ? null : onNotInterested,
                    expand: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final String counter;

  const _CounterPill(this.counter);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      child: Text(
        counter,
        style: AppTypography.monoLabel(
          color: context.colors.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}
