import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The library's status tabs, with the selected pill taking on that status's
/// colour and interpolating between them as the user swipes.
///
/// The colour follows the swipe rather than snapping at the halfway point, so
/// the pill reads as one object travelling between tabs.
class LibraryTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;

  /// Entry counts per status key. Missing keys read as zero.
  final Map<String, int> counts;

  final bool isLandscape;

  static const double _height = 48;

  const LibraryTabBar({
    super.key,
    required this.controller,
    required this.counts,
    required this.isLandscape,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final showCounts = SettingsManager().showLibraryTabCounts;
    final tabs = LibraryScreenConstants.tabs;

    return AnimatedBuilder(
      // The controller's animation drives the colour blend; without it the
      // pill would only recolour once the swipe had settled.
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final position =
            controller.animation?.value ?? controller.index.toDouble();
        final maxIndex = tabs.length - 1;
        final lower = position.floor().clamp(0, maxIndex);
        final upper = position.ceil().clamp(0, maxIndex);
        final t = (position - lower).clamp(0.0, 1.0);

        final indicatorColor =
            Color.lerp(
              context.colors.forState(tabs[lower].key),
              context.colors.forState(tabs[upper].key),
              t,
            ) ??
            context.colors.forState(tabs[lower].key);

        return TabBar(
          controller: controller,
          isScrollable: true,
          // Centred in landscape, where the tabs do not fill the width and a
          // left-aligned row leaves a conspicuous gap.
          tabAlignment: isLandscape ? TabAlignment.center : TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 6,
          ),
          labelPadding: EdgeInsets.zero,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              _LibraryTab(
                label: l10n.translate(tabs[i].key),
                stateKey: tabs[i].key,
                count: showCounts ? (counts[tabs[i].key] ?? 0) : null,
                // 1.0 when fully selected, 0.0 when fully unselected, and
                // partway through a swipe for the two tabs either side of it.
                selectionWeight: (1.0 - (position - i).abs()).clamp(0.0, 1.0),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryTab extends StatelessWidget implements PreferredSizeWidget {
  final String label;
  final String stateKey;

  /// Null hides the count entirely.
  final int? count;

  final double selectionWeight;

  const _LibraryTab({
    required this.label,
    required this.stateKey,
    required this.count,
    required this.selectionWeight,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    // The label sits on the coloured pill once selected, so it crosses to that
    // status's ink as the pill arrives under it.
    final onColor = context.colors.onForState(stateKey);
    final labelColor =
        Color.lerp(context.colors.text, onColor, selectionWeight) ??
        context.colors.text;

    return Tab(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.display(fontSize: 13, color: labelColor),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                NumberUtils.formatCount(count!),
                style: AppTypography.display(
                  fontSize: 12,
                  // Dimmer than the label: a count is secondary information,
                  // and at full strength it competes with the tab name.
                  color:
                      Color.lerp(
                        context.colors.textMuted,
                        onColor.withValues(alpha: 0.6),
                        selectionWeight,
                      ) ??
                      context.colors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
