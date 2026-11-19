import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_icons.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';

@immutable
class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
}

/// The index is the tab index: reordering moves where deep links and tab jumps land.
const List<NavItem> navItems = [
  NavItem(
    icon: MbIcons.house,
    selectedIcon: MbIcons.houseFill,
    labelKey: 'home',
  ),
  NavItem(
    icon: MbIcons.bookmark,
    selectedIcon: MbIcons.bookmarkFill,
    labelKey: 'library',
  ),
  NavItem(
    icon: MbIcons.compass,
    selectedIcon: MbIcons.compassFill,
    labelKey: 'browse',
  ),
  NavItem(
    icon: MbIcons.newspaper,
    selectedIcon: MbIcons.newspaperFill,
    labelKey: 'news',
  ),
  NavItem(
    icon: MbIcons.user,
    selectedIcon: MbIcons.userFill,
    labelKey: 'profile',
  ),
];

class NavTabs {
  NavTabs._();

  static const int home = 0;
  static const int library = 1;
  static const int browse = 2;
  static const int news = 3;
  static const int profile = 4;
}

List<MbNavDestination> navDestinations(LocalizationService l10n) => [
  for (final item in navItems)
    MbNavDestination(
      icon: item.icon,
      selectedIcon: item.selectedIcon,
      label: l10n.translate(item.labelKey),
    ),
];
