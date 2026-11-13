part of 'desktop_sidebar.dart';

/// The signed-in account at the foot of the sidebar, or a sign-in prompt.
class _AccountChip extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _AccountChip({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = getIt<ProfileAuthService>();
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final l10n = LocalizationService();
        final profile = auth.cachedProfile;
        final name = profile == null
            ? l10n.translate('sign_in')
            : (profile.nickname?.isNotEmpty == true
                  ? profile.nickname!
                  : profile.preferredUsername ?? l10n.translate('profile'));
        final initial = profile == null
            ? null
            : (name.isNotEmpty ? name[0].toUpperCase() : '?');

        final avatar = Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: profile == null
                ? context.colors.surfaceRaised
                : context.colors.accent.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                ? WidgetUtils.networkImage(
                    url: profile.avatarUrl!,
                    fit: BoxFit.cover,
                    width: 34,
                    height: 34,
                    memCacheWidth: WidgetUtils.decodeWidth(context, 34),
                    errorWidget: Center(
                      child: Text(
                        initial ?? '?',
                        style: AppTypography.display(
                          color: context.colors.accent,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: initial == null
                        ? Icon(
                            Icons.login_rounded,
                            size: 17,
                            color: context.colors.textMuted,
                          )
                        : Text(
                            initial,
                            style: AppTypography.display(
                              color: context.colors.accent,
                              fontSize: 15,
                            ),
                          ),
                  ),
          ),
        );

        return DesktopHoverSurface(
          onTap: onTap,
          tooltip: collapsed ? name : null,
          hoverColor: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              avatar,
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: context.colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        profile == null
                            ? l10n.translate('sign_in_subtitle')
                            : 'v${AppConstants.appVersion}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.sans(
                          color: context.colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
