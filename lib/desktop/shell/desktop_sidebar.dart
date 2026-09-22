import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The desktop app's permanent left sidebar: brand, a search shortcut, the
/// five destinations with their labels, and settings and the account pinned
/// to the bottom.
///
/// Labels are always shown when expanded — a mouse user scans text, and the
/// phone's icon-only bar only made sense because it had no room.
class DesktopSidebar extends StatelessWidget {
  /// 0–4 are [navItems]; [settingsIndex] is the settings page.
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  static const int settingsIndex = 5;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSearch,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final width = collapsed
        ? DesktopTokens.sidebarCollapsedWidth
        : DesktopTokens.sidebarWidth;

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.emphasized,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.backgroundDeep,
        border: Border(right: BorderSide(color: context.colors.border)),
      ),
      child: ClipRect(
        child: OverflowBox(
          // Lay out at the target width immediately so the labels do not
          // reflow through every frame of the collapse animation.
          alignment: Alignment.topLeft,
          minWidth: width,
          maxWidth: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 13),
                    _Brand(collapsed: collapsed, onToggle: onToggleCollapsed),
                    const SizedBox(height: 22),
                    for (var i = 0; i < navItems.length; i++) ...[
                      _SidebarItem(
                        icon: selectedIndex == i
                            ? navItems[i].selectedIcon
                            : navItems[i].icon,
                        label: l10n.translate(navItems[i].labelKey),
                        shortcut: 'Ctrl+${i + 1}',
                        selected: selectedIndex == i,
                        collapsed: collapsed,
                        onTap: () => onSelected(i),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Spacer(),
                    _SidebarItem(
                      icon: selectedIndex == settingsIndex
                          ? Icons.settings
                          : Icons.settings_outlined,
                      label: l10n.translate('settings'),
                      shortcut: 'Ctrl+,',
                      selected: selectedIndex == settingsIndex,
                      collapsed: collapsed,
                      onTap: () => onSelected(settingsIndex),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: context.colors.border),
                    const SizedBox(height: 10),
                    _AccountChip(
                      collapsed: collapsed,
                      onTap: () => onSelected(NavTabs.profile),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
                // Halfway down the collapsed bar, where its edge would open from:
                // the logo at the top also expands it, but nothing says so.
                if (collapsed)
                  Align(
                    alignment: Alignment.center,
                    child: DesktopIconButton(
                      icon: Icons.keyboard_double_arrow_right_rounded,
                      size: 20,
                      filled: true,
                      tooltip: l10n.translate('expand_sidebar'),
                      onPressed: onToggleCollapsed,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const _Brand({required this.collapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final logo = Image.asset('assets/mangabaka512.png', width: 32, height: 32);

    if (collapsed) {
      return Center(
        child: Tooltip(
          message: l10n.translate('expand_sidebar'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(onTap: onToggle, child: logo),
          ),
        ),
      );
    }

    return Row(
      children: [
        const SizedBox(width: 4),
        logo,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'MANGABAKA',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 17,
            ),
          ),
        ),
        DesktopIconButton(
          icon: Icons.keyboard_double_arrow_left_rounded,
          size: 18,
          color: context.colors.textMuted,
          tooltip: l10n.translate('collapse_sidebar'),
          onPressed: onToggle,
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onAccent : context.colors.textMuted;
    return DesktopHoverSurface(
      onTap: onTap,
      selected: selected,
      selectedColor: context.colors.accent,
      hoverColor: context.colors.surface,
      tooltip: collapsed ? '$label  ($shortcut)' : null,
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : 12,
        vertical: 11,
      ),
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: selected ? fg : context.colors.text),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  color: selected ? fg : context.colors.text,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
