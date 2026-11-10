import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_icons.dart';
import 'package:mangabaka_app/core/widgets/design/mb_nav.dart';

/// One top-level destination: its outline and filled glyphs, and the key its
/// label is translated from.
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

/// The app's five top-level destinations, in tab order.
///
/// The index into this list *is* the tab index — `MainScreen.setTabIndex(2)`
/// means Browse — so reordering it changes what deep links and cross-screen
/// jumps land on.
///
/// Phosphor rather than Material: the reference's nav is a thin, rounded,
/// geometric family with a matched solid weight for the active state, which
/// Material's icons do not provide. Compass and user match the reference
/// directly; the bookmark stands in for the library. See [MbIcons].
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

/// Tab indices referred to by name, so a cross-screen jump reads as a
/// destination rather than a magic number.
class NavTabs {
  NavTabs._();

  static const int home = 0;
  static const int library = 1;
  static const int browse = 2;
  static const int news = 3;
  static const int profile = 4;
}

/// [navItems] as the destinations the rail and bottom bar take, with labels
/// resolved through [l10n].
List<MbNavDestination> navDestinations(LocalizationService l10n) => [
  for (final item in navItems)
    MbNavDestination(
      icon: item.icon,
      selectedIcon: item.selectedIcon,
      label: l10n.translate(item.labelKey),
    ),
];
