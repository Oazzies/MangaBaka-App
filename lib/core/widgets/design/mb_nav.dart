import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// One destination in [MbBottomNav] / [MbNavRail].
@immutable
class MbNavDestination {
  final IconData icon;
  final IconData selectedIcon;

  /// Used as the tooltip and the accessibility label; the reference's nav is
  /// icon-only, so it is never painted.
  final String label;

  const MbNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// The selected-destination marker: a solid amber disc behind an ink icon.
/// Shared by the bar and the rail so both read identically.
class _MbNavItem extends StatelessWidget {
  final MbNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  const _MbNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.overshoot,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? context.colors.accent : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        selected ? destination.selectedIcon : destination.icon,
        size: 23,
        color: selected ? context.colors.onAccent : context.colors.textMuted,
      ),
    );

    if (expand) {
      child = Center(child: child);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: expand
            ? const EdgeInsets.symmetric(horizontal: 1.0)
            : EdgeInsets.zero,
        child: Tooltip(
          message: destination.label,
          child: InkResponse(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            containedInkWell: expand,
            radius: expand ? null : 28,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Icon-only bottom bar with an amber disc on the active destination —
/// the reference's navigation. Replaces Material's [NavigationBar].
class MbBottomNav extends StatelessWidget {
  final List<MbNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MbBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _MbNavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                    expand: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vertical counterpart of [MbBottomNav] for the tablet/desktop left and right
/// rail layouts. Replaces Material's [NavigationRail].
class MbNavRail extends StatelessWidget {
  final List<MbNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? leading;

  /// Pinned to the bottom of the rail (e.g. the settings button).
  final Widget? trailing;

  const MbNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.background,
      child: Column(
        children: [
          if (leading != null) leading!,
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _MbNavItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
            ),
          if (trailing != null)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: trailing!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
