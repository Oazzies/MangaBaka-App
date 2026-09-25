import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// What Browse shows before anything is searched: Mix as a feature card, then
/// one card per content type with its three ready-made lists.
///
/// The phone stacks these as fifteen full-width buttons; here each type is a
/// card and the cards sit side by side.
class DesktopBrowseLanding extends StatelessWidget {
  final void Function(String header, String sortBy, {String? type}) onNavigate;
  final VoidCallback onMix;
  final VoidCallback onDiscoveryQueue;

  const DesktopBrowseLanding({
    super.key,
    required this.onNavigate,
    required this.onMix,
    required this.onDiscoveryQueue,
  });

  /// (API type, l10n key for the card title).
  static const List<(String, String)> _types = [
    ('manga', 'type_manga'),
    ('manhwa', 'type_manhwa'),
    ('manhua', 'type_manhua'),
    ('novel', 'novels'),
    ('oel', 'oel_other'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        14,
        DesktopTokens.pagePadding,
        40,
      ),
      children: [
        DerivedLayoutBuilder<bool>(
          derive: (constraints) => constraints.maxWidth >= 720,
          builder: (context, isWide) {
            final queueCard = _DiscoveryQueueCard(onTap: onDiscoveryQueue);
            final mixCard = _MixCard(onTap: onMix);
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: queueCard),
                  const SizedBox(width: 16),
                  Expanded(child: mixCard),
                ],
              );
            }
            return Column(
              children: [queueCard, const SizedBox(height: 12), mixCard],
            );
          },
        ),
        const SizedBox(height: DesktopTokens.sectionGap),
        DesktopSectionTitle(title: l10n.translate('discover')),
        // Columns are a whole number decided per breakpoint; their width
        // comes from the Row at layout, so a resize never rebuilds a card.
        DerivedLayoutBuilder<int>(
          derive: (constraints) =>
              (constraints.maxWidth / 250).floor().clamp(2, 5),
          builder: (context, columns) {
            const gap = 16.0;
            final cards = [
              for (final (type, key) in _types)
                _TypeCard(
                  title: l10n.translate(key),
                  onPopular: () => onNavigate(
                    l10n.translate('most_popular'),
                    'popularity_asc',
                    type: type,
                  ),
                  onTopRated: () => onNavigate(
                    l10n.translate('top_rated'),
                    'score_desc',
                    type: type,
                  ),
                  onRandom: () => onNavigate(
                    l10n.translate('random'),
                    'random',
                    type: type,
                  ),
                ),
            ];
            return Column(
              children: [
                for (var r = 0; r < cards.length; r += columns) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: gap),
                        Expanded(
                          child: r + c < cards.length
                              ? cards[r + c]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DiscoveryQueueCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DiscoveryQueueCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopHoverSurface(
      onTap: onTap,
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.fromLTRB(30, 26, 26, 26),
      // The button beside the text while the text keeps its room, beneath
      // it in a narrow card or at a large text size.
      child: BesideOrBelow(
        minBodyWidth: 180,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: context.colors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.translate('discovery_queue').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('discovery_queue_subtitle'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
        trailing: DesktopPillButton(
          label: l10n.translate('discovery_queue_start'),
          primary: true,
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MixCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopHoverSurface(
      onTap: onTap,
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.fromLTRB(30, 26, 26, 26),
      // The button beside the text while the text keeps its room, beneath
      // it in a narrow card or at a large text size.
      child: BesideOrBelow(
        minBodyWidth: 180,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('mix').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('mix_subtitle'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
        trailing: DesktopPillButton(
          label: l10n.translate('mix_empty_title'),
          primary: true,
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final VoidCallback onPopular;
  final VoidCallback onTopRated;
  final VoidCallback onRandom;

  const _TypeCard({
    required this.title,
    required this.onPopular,
    required this.onTopRated,
    required this.onRandom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Link(label: l10n.translate('most_popular'), onTap: onPopular),
          _Link(label: l10n.translate('top_rated'), onTap: onTopRated),
          _Link(label: l10n.translate('random'), onTap: onRandom),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Link({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sans(
                color: context.colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.colors.textMuted,
          ),
        ],
      ),
    );
  }
}
