import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/features/series/widgets/series_filter_drawer.dart';

/// The desktop counterpart of the phone's filter sheet: a panel docked to the
/// right edge of a series page, opened by right-clicking a tag, genre or other
/// chip and then fed by clicking more of them.
///
/// A bottom sheet with a drag handle and a marching border suits a thumb; here
/// the page stays fully visible and clickable beside a fixed-width panel, so
/// chips can be picked on the page while the filters take shape next to it.
class DesktopSeriesFilterPanel extends StatelessWidget {
  final SeriesFilterDrawerController controller;

  /// Runs the assembled filters as a Browse search.
  final ValueChanged<SearchFilters> onSearch;

  static const double width = 380;

  const DesktopSeriesFilterPanel({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.isOpen) return const SizedBox.shrink();

    final slide = controller.drawerAnimation.drive(
      Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );

    // A full-height sidebar, laid out like the Upcoming Releases rail: its
    // content starts below the window controls rather than the panel itself
    // being inset.
    return Align(
      alignment: Alignment.centerRight,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: controller.drawerAnimation,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: context.colors.background,
              border: Border(left: BorderSide(color: context.colors.border)),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowAt(0.28),
                  blurRadius: 24,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelHeader(controller: controller, onSearch: onSearch),
                Divider(height: 1, color: context.colors.border),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      const _Hint(),
                      const SizedBox(height: 12),
                      SeriesFilterSections(controller: controller),
                    ],
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

class _PanelHeader extends StatelessWidget {
  final SeriesFilterDrawerController controller;
  final ValueChanged<SearchFilters> onSearch;

  const _PanelHeader({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final filters = controller.filters;
    final count = filters?.activeFiltersCount ?? 0;

    return Padding(
      // Same inset as the Upcoming Releases header: clear of the window
      // controls.
      padding: const EdgeInsets.fromLTRB(20, 56, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (count > 0
                      ? '${l10n.translate('filters')} ($count)'
                      : l10n.translate('filters'))
                  .toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 18,
              ),
            ),
          ),
          DesktopPillButton(
            label: l10n.translate('search'),
            icon: Icons.search_rounded,
            primary: true,
            onPressed: filters == null || count == 0
                ? null
                : () => onSearch(filters),
          ),
          const SizedBox(width: 8),
          DesktopIconButton(
            icon: Icons.close_rounded,
            tooltip: l10n.translate('reset'),
            onPressed: controller.close,
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mouse_outlined, size: 16, color: context.colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LocalizationService().translate('filter_panel_hint'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
