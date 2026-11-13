part of 'desktop_profile_screen.dart';

class _IdentityCard extends StatelessWidget {
  final String name;
  final String? username;
  final String role;
  final String? avatarUrl;
  final VoidCallback onLogout;

  const _IdentityCard({
    required this.name,
    required this.username,
    required this.role,
    this.avatarUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.all(28),
      // The account buttons beside the name while it keeps its room,
      // beneath it in a narrow window or at a large text size.
      child: BesideOrBelow(
        gap: 24,
        minBodyWidth: 220,
        leading: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: context.colors.accent,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? WidgetUtils.networkImage(
                    url: avatarUrl!,
                    fit: BoxFit.cover,
                    width: 88,
                    height: 88,
                    memCacheWidth: WidgetUtils.decodeWidth(context, 88),
                    errorWidget: Center(
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: AppTypography.display(
                          color: context.colors.onAccent,
                          fontSize: 40,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: AppTypography.display(
                        color: context.colors.onAccent,
                        fontSize: 40,
                      ),
                    ),
                  ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (username != null && username != name) ...[
                  // Usernames have no length limit; the role pill keeps
                  // its place and the name gives way.
                  Flexible(
                    child: Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sans(
                        color: context.colors.textMuted,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(
                        AppConstants.pillRadius,
                      ),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DesktopPillButton(
              label: l10n.translate('account_settings'),
              icon: Icons.open_in_new_rounded,
              onPressed: () => launchUrl(
                Uri.parse('https://mangabaka.org/my/settings/profile'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            DesktopIconButton(
              icon: Icons.logout_rounded,
              filled: true,
              color: context.colors.error,
              tooltip: l10n.translate('logout'),
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoLabel(
                color: context.colors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            maxLines: 1,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandoutCard extends StatelessWidget {
  final LibraryEntryWithSeries entry;
  final String label;
  final IconData icon;
  final String value;

  const _StandoutCard({
    required this.entry,
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final series = DbToApiMapper.seriesFromDb(entry.series);
    return DesktopHoverSurface(
      onTap: () => openSeriesDetail(context, series, heroTag: 'standout'),
      idleColor: context.colors.surface,
      hoverColor: context.colors.surfaceRaised,
      borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: WidgetUtils.networkImage(
              url: series.coverUrl,
              blurred: WidgetUtils.isRatingBlurred(series.contentRating),
              width: 72,
              height: 108,
              memCacheWidth: 160,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: context.colors.star),
                    const SizedBox(width: 6),
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.monoLabel(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  series.getDisplayTitle(
                    SettingsManager().defaultTitleLanguage,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.sans(
                    color: context.colors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
