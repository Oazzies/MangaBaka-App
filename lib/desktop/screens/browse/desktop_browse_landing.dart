import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/lucide_icon.dart';
import 'package:mangabaka_app/core/widgets/design/mb_icons.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_hub_screen.dart';

part 'desktop_browse_landing_cards_part.dart';

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

  static const List<({String apiType, String titleKey})> _types = [
    (apiType: 'manga', titleKey: 'type_manga'),
    (apiType: 'manhwa', titleKey: 'type_manhwa'),
    (apiType: 'manhua', titleKey: 'type_manhua'),
    (apiType: 'novel', titleKey: 'novels'),
    (apiType: 'oel', titleKey: 'oel_other'),
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
        DerivedLayoutBuilder<({bool isWide, bool isStacked})>(
          derive: (constraints) {
            final isWide = constraints.maxWidth >= 720;
            final cardWidth = isWide
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return (isWide: isWide, isStacked: cardWidth < 680);
          },
          builder: (context, layout) {
            final queueCard = _DiscoveryQueueCard(
              onTap: onDiscoveryQueue,
              isStacked: layout.isStacked,
            );
            final mixCard = _MixCard(
              onTap: onMix,
              isStacked: layout.isStacked,
            );
            if (layout.isWide) {
              // responsive-ok: Discovery Queue and Mix surfaces match the taller card's height.
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: queueCard),
                    const SizedBox(width: 16),
                    Expanded(child: mixCard),
                  ],
                ),
              );
            }
            return Column(
              children: [queueCard, const SizedBox(height: 12), mixCard],
            );
          },
        ),
        const SizedBox(height: 16),
        _StacksCard(onTap: () => StacksHubScreen.open(context)),
        const SizedBox(height: DesktopTokens.sectionGap),
        DesktopSectionTitle(title: l10n.translate('discover')),
        DerivedLayoutBuilder<int>(
          derive: (constraints) =>
              (constraints.maxWidth / 250).floor().clamp(2, 5),
          builder: (context, columns) {
            const gap = 16.0;
            final cards = [
              for (final (:apiType, :titleKey) in _types)
                _TypeCard(
                  title: l10n.translate(titleKey),
                  onPopular: () => onNavigate(
                    l10n.translate('most_popular'),
                    'popularity_asc',
                    type: apiType,
                  ),
                  onTopRated: () => onNavigate(
                    l10n.translate('top_rated'),
                    'score_desc',
                    type: apiType,
                  ),
                  onRandom: () => onNavigate(
                    l10n.translate('random'),
                    'random',
                    type: apiType,
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

class _FeatureCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String title;
  final String buttonLabel;
  final bool isStacked;

  const _FeatureCard({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.isStacked,
  });

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );

    final button = DesktopPillButton(
      label: buttonLabel,
      primary: true,
      onPressed: onTap,
    );

    final Widget content;
    if (isStacked) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [titleRow, const SizedBox(height: 14), button],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleRow),
          const SizedBox(width: 16),
          button,
        ],
      );
    }

    return DesktopHoverSurface(
      onTap: onTap,
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.fromLTRB(30, 26, 26, 26),
      child: content,
    );
  }
}

class _DiscoveryQueueCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isStacked;

  const _DiscoveryQueueCard({required this.onTap, this.isStacked = false});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return _FeatureCard(
      onTap: onTap,
      isStacked: isStacked,
      icon: Icon(MbIcons.compass, size: 22, color: context.colors.accent),
      title: l10n.translate('discovery_queue'),
      buttonLabel: l10n.translate('discovery_queue_start'),
    );
  }
}

class _MixCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isStacked;

  const _MixCard({required this.onTap, this.isStacked = false});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return _FeatureCard(
      onTap: onTap,
      isStacked: isStacked,
      icon: MbLucideIcon(
        LucideGlyph.flaskConical,
        size: 22,
        color: context.colors.accent,
      ),
      title: l10n.translate('mix'),
      buttonLabel: l10n.translate('mix_empty_title'),
    );
  }
}
