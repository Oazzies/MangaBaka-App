import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/dotted_border_painter.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_categories_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_details_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_sort_section.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_type_status_section.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

/// The filter sheet that long-pressing a chip on the series detail screen
/// raises, together with the marching-ants frame that marks the mode.
///
/// Renders nothing when the controller is closed, so the caller can include it
/// unconditionally.
class SeriesFilterDrawer extends StatelessWidget {
  final SeriesFilterDrawerController controller;

  /// Runs the assembled filters as a Browse search.
  final ValueChanged<SearchFilters> onSearch;

  static const List<String> types = [
    'manga',
    'manhwa',
    'manhua',
    'novel',
    'oel',
  ];

  static const List<String> statuses = [
    'ongoing',
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
  ];

  const SeriesFilterDrawer({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  static Map<String, String> sortOptions(LocalizationService l10n) => {
    'name_asc': l10n.translate('title_asc'),
    'name_desc': l10n.translate('title_desc'),
    'popularity_asc': l10n.translate('popularity_asc'),
    'popularity_desc': l10n.translate('popularity_desc'),
    'score_desc': l10n.translate('rating_desc'),
    'score_asc': l10n.translate('rating_asc'),
    'chapters_desc': l10n.translate('chapters_desc'),
    'chapters_asc': l10n.translate('chapters_asc'),
    'random': l10n.translate('random_sort'),
  };

  @override
  Widget build(BuildContext context) {
    if (!controller.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: controller.drawerAnimation,
              child: AnimatedBuilder(
                animation: controller.marchingAnts,
                builder: (context, _) => CustomPaint(
                  painter: DottedBorderPainter(
                    color: context.colors.accent,
                    strokeWidth: 3,
                    gap: 6,
                    // One full 4s lap advances the dashes by 24px — four
                    // pattern repeats at gap 6.
                    phase: controller.marchingAnts.value * 24.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SlideTransition(
            position: controller.drawerSlide,
            child: FadeTransition(
              // Fades in over the first half of the slide so the sheet is
              // legible before it has finished travelling.
              opacity: CurvedAnimation(
                parent: controller.drawerAnimation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
              ),
              child: _Sheet(controller: controller, onSearch: onSearch),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  final SeriesFilterDrawerController controller;
  final ValueChanged<SearchFilters> onSearch;

  /// Height of the collapsed sheet — just the header — above the system inset.
  static const double _headerHeight = 84.0;

  const _Sheet({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Collapsed, the sheet should still clear the system navigation bar and
    // leave its header reachable.
    final minSize = screenHeight > 0
        ? ((_headerHeight + mediaQuery.padding.bottom) / screenHeight).clamp(
            0.05,
            0.9,
          )
        : 0.12;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: minSize,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: [minSize, 0.5, 0.85],
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowAt(0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border(
              top: BorderSide(color: context.colors.surfaceRaised, width: 1),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _Header(controller: controller, onSearch: onSearch),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _FilterSections(controller: controller),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SeriesFilterDrawerController controller;
  final ValueChanged<SearchFilters> onSearch;

  const _Header({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final filters = controller.filters;
    final activeCount = filters?.activeFiltersCount ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.surfaceRaised,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: controller.close,
                child: Text(
                  l10n.translate('reset').toUpperCase(),
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                activeCount > 0
                    ? '${l10n.translate('filters')} ($activeCount)'
                    : l10n.translate('filters'),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: filters == null ? null : () => onSearch(filters),
                style: TextButton.styleFrom(
                  backgroundColor: context.colors.accent.withValues(
                    alpha: 0.15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  l10n.translate('search').toUpperCase(),
                  style: AppTypography.sans(
                    color: context.colors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSections extends StatelessWidget {
  final SeriesFilterDrawerController controller;

  const _FilterSections({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;
    if (filters == null) return const SizedBox.shrink();

    if (controller.isLoadingMetadata) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: MbSpinner()),
      );
    }

    final l10n = LocalizationService();
    final onChanged = controller.replaceFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchFilterSortSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          sortOptions: SeriesFilterDrawer.sortOptions(l10n),
        ),
        const SizedBox(height: 8),
        SearchFilterCategoriesSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          genres: controller.genres,
          tags: controller.tags,
        ),
        const SizedBox(height: 8),
        SearchFilterTypeStatusSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
          types: SeriesFilterDrawer.types,
          statuses: SeriesFilterDrawer.statuses,
        ),
        const SizedBox(height: 8),
        SearchFilterDetailsSection(
          filters: filters,
          onFiltersChanged: onChanged,
          l10n: l10n,
        ),
        SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}
