import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/content_rating_filter.dart';
import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_badge.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/models/sort_options.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/tri_state_chip.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_filter_sections_part.dart';
part 'desktop_filter_taxonomy_part.dart';
part 'desktop_filter_controls_part.dart';
part 'desktop_filter_inputs_part.dart';

/// Sliders commit on release, not every tick, since each change may start a network search.
class DesktopFilterPanel extends StatefulWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;
  final SeriesSearchService searchService;
  final MetadataService metadata;

  /// The library filters locally by tag name; the search API takes ids.
  final bool tagsByName;

  final Widget? header;

  final bool enabled;
  final String? disabledMessage;

  const DesktopFilterPanel({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.searchService,
    required this.metadata,
    this.tagsByName = false,
    this.header,
    this.enabled = true,
    this.disabledMessage,
  });

  @override
  State<DesktopFilterPanel> createState() => _DesktopFilterPanelState();
}

class _DesktopFilterPanelState extends State<DesktopFilterPanel> {
  static const int _collapsedGenreCount = 16;
  static const int _maxTagMatches = 40;

  List<Map<String, dynamic>> _genres = const [];
  List<Map<String, dynamic>> _tags = const [];

  bool _showAllGenres = false;
  String _tagQuery = '';
  final TextEditingController _tagSearch = TextEditingController();

  RangeValues? _draggingRating;
  RangeValues? _draggingYear;

  static final int _minYear = 1950;
  static final int _maxYear = DateTime.now().year + 1;

  SearchFilters get _f => widget.filters;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _tagSearch.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final service = widget.searchService;
    try {
      final results = await Future.wait([
        service.getGenres(),
        service.getTags(),
      ]);
      if (!mounted) return;
      setState(() {
        _genres = results[0];
        _tags = results[1];
      });
    } catch (e, st) {
      // The panel works without the vocabularies; their lists just stay empty.
      LoggingService.logger.fine(
        'Failed to load filter metadata vocabularies',
        e,
        st,
      );
    }
  }

  void _emit(SearchFilters next) => widget.onChanged(next);

  void _updateState(VoidCallback fn) => setState(fn);

  TriState _stateOf(String value, List<String> inc, List<String> exc) {
    if (inc.contains(value)) return TriState.include;
    if (exc.contains(value)) return TriState.exclude;
    return TriState.off;
  }

  (List<String>, List<String>) _apply(
    String value,
    TriState next,
    List<String> inc,
    List<String> exc,
  ) {
    final newInc = List<String>.from(inc)..remove(value);
    final newExc = List<String>.from(exc)..remove(value);
    if (next == TriState.include) newInc.add(value);
    if (next == TriState.exclude) newExc.add(value);
    return (newInc, newExc);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final filterCount =
        _f.activeFiltersCount -
        ((_f.sortBy != null && _f.sortBy!.isNotEmpty) ? 1 : 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 28),
        ],
        Row(
          children: [
            Text(
              l10n.translate('filters').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 17,
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: 8),
              MbBadge.accent(label: '$filterCount'),
            ],
            const Spacer(),
            if (filterCount > 0 && widget.enabled)
              _TextAction(
                label: l10n.translate('clear_all'),
                onTap: () => _emit(SearchFilters(sortBy: _f.sortBy)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (!widget.enabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.disabledMessage ?? '',
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 13,
              ),
            ),
          )
        else
          ..._sections(l10n),
      ],
    );
  }
}
