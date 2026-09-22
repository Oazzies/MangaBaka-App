import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/widgets/top_nav_search_field.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The horizontal navigation bar used on wide landscape windows: brand, tabs,
/// the current tab's search field, and settings.
///
/// A desktop-shaped chrome rather than a rail — at this width a row of labelled
/// tabs costs no content space and leaves room for a persistent search field,
/// which the rail layouts have nowhere to put.
class MainTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final LocalizationService l10n;

  /// Whether this window is wide enough to host the current tab's search
  /// field. When false the slot is left out entirely and the screen draws its
  /// own field.
  final bool showSearchField;

  static const double _height = 72;

  /// Fixed width for the search slot: letting it flex would make the tabs
  /// shift sideways as the field appeared and disappeared between tabs.
  static const double _searchWidth = 320;

  const MainTopNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.l10n,
    required this.showSearchField,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final searchField = showSearchField
        ? TopNavSearchField.build(selectedIndex)
        : null;

    final rightPadding = DesktopLayout.isDesktopPlatform
        ? DesktopTokens.windowControlsClearance
        : 20.0;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: context.colors.background,
        border: Border(
          bottom: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: rightPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 780;

              return Row(
                children: [
                  _Brand(compact: isCompact),
                  SizedBox(width: isCompact ? 16 : 28),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < navItems.length; i++)
                            _NavTab(
                              item: navItems[i],
                              label: l10n.translate(navItems[i].labelKey),
                              isSelected: selectedIndex == i,
                              compact: isCompact,
                              onTap: () => onDestinationSelected(i),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (searchField != null) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isCompact ? 160 : _searchWidth,
                      ),
                      child: searchField,
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const SizedBox(width: 8),
                  WidgetUtils.tooltip(
                    message: l10n.translate('settings'),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      iconSize: 20,
                      onPressed: () => SettingsScreen.show(context),
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool compact;

  const _Brand({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.denseRadius),
          ),
          child: Image.asset('assets/mangabaka512.png', width: 28, height: 28),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'MANGABAKA',
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 17,
            ),
          ),
        ],
      ],
    );
  }
}

/// One tab: icon, label, and an underline that animates in when selected.
class _NavTab extends StatelessWidget {
  final NavItem item;
  final String label;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.label,
    required this.isSelected,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.colors.text : context.colors.textMuted;

    final tabContent = InkWell(
      onTap: onTap,
      // Square: the underline is the selection cue, and a rounded hover
      // shape would fight it.
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? context.colors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 18,
              color: color,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTypography.display(fontSize: 13, color: color),
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(right: compact ? 12 : 20),
      child: compact
          ? WidgetUtils.tooltip(message: label, child: tabContent)
          : tabContent,
    );
  }
}
