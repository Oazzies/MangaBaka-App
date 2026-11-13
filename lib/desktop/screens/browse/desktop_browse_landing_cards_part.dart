part of 'desktop_browse_landing.dart';

/// Stacks: hand-picked lists from the community, as a full-width feature
/// card under Mix and the queue.
class _StacksCard extends StatelessWidget {
  final VoidCallback onTap;

  const _StacksCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopHoverSurface(
      onTap: onTap,
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.fromLTRB(30, 22, 26, 22),
      child: BesideOrBelow(
        minBodyWidth: 180,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.layers_rounded,
                  size: 22,
                  color: context.colors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.translate('stacks').toUpperCase(),
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
              l10n.translate('stacks_tagline'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
        trailing: DesktopPillButton(
          label: l10n.translate('stacks_browse'),
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
          _Link(
            label: l10n.translate('most_popular'),
            icon: LucideGlyph.star,
            onTap: onPopular,
          ),
          _Link(
            label: l10n.translate('top_rated'),
            icon: LucideGlyph.heart,
            onTap: onTopRated,
          ),
          _Link(
            label: l10n.translate('random'),
            icon: LucideGlyph.dices,
            onTap: onRandom,
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final LucideGlyph icon;
  final VoidCallback onTap;

  const _Link({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          MbLucideIcon(icon, size: 17, color: context.colors.accent),
          const SizedBox(width: 10),
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
