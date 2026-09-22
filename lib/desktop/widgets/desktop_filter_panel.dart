import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
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

/// Every search filter laid out inline, applied the moment it changes.
///
/// The phone hides filters behind a sheet because there is no room for them
/// beside the results; a desktop window has that room, so the filters sit in a
/// permanent column and the results update as they are toggled — no Apply
/// step, no popup covering what is being filtered.
///
/// Sliders commit when released rather than on every tick, since each change
/// may start a network search.
class DesktopFilterPanel extends StatefulWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  /// Whether tags are filtered by name rather than id. The library filters
  /// locally against the tag names stored on each series; the search API
  /// takes ids.
  final bool tagsByName;

  /// Shown above the filters (the library's status list goes here).
  final Widget? header;

  /// When false the filters are shown disabled with [disabledMessage] — for
  /// result types the filters do not apply to.
  final bool enabled;
  final String? disabledMessage;

  const DesktopFilterPanel({
    super.key,
    required this.filters,
    required this.onChanged,
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

  /// Slider positions while being dragged, before they are committed.
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
    final service = getIt<SeriesSearchService>();
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
    } catch (_) {
      // The panel still works without the vocabularies: types, statuses and
      // ranges need none, and the lists simply stay empty.
    }
  }

  void _emit(SearchFilters next) => widget.onChanged(next);

  // ─── Tri-state helpers ───────────────────────────────────────────────────

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

  // ─── Build ───────────────────────────────────────────────────────────────

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

  List<Widget> _sections(LocalizationService l10n) {
    return [
      _Section(
        title: l10n.translate('type'),
        child: _chipWrap([
          for (final t in filterSeriesTypes)
            _chip(
              label: l10n.translate('type_$t'),
              state: _stateOf(t, _f.type, _f.typeNot),
              onChanged: (s) {
                final (inc, exc) = _apply(t, s, _f.type, _f.typeNot);
                _emit(_f.copyWith(type: inc, typeNot: exc));
              },
            ),
        ]),
      ),
      _Section(
        title: l10n.translate('status'),
        child: _chipWrap([
          for (final s in filterPublicationStatuses)
            _chip(
              label: l10n.translate('status_$s'),
              state: _stateOf(s, _f.status, _f.statusNot),
              onChanged: (next) {
                final (inc, exc) = _apply(s, next, _f.status, _f.statusNot);
                _emit(_f.copyWith(status: inc, statusNot: exc));
              },
            ),
        ]),
      ),
      _Section(title: l10n.translate('genres'), child: _genreSection(l10n)),
      _Section(title: l10n.translate('tags'), child: _tagSection(l10n)),
      _Section(
        title: l10n.translate('rating_range'),
        trailing: _rangeLabel(
          _draggingRating ?? RangeValues(_f.ratingLower, _f.ratingUpper),
          (v) => v.toInt().toString(),
        ),
        child: RangeSlider(
          values:
              _draggingRating ?? RangeValues(_f.ratingLower, _f.ratingUpper),
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: (v) => setState(() => _draggingRating = v),
          onChangeEnd: (v) {
            setState(() => _draggingRating = null);
            _emit(_f.copyWith(ratingLower: v.start, ratingUpper: v.end));
          },
        ),
      ),
      _Section(
        title: l10n.translate('publication_year'),
        trailing: _rangeLabel(
          _draggingYear ?? _yearValues(),
          (v) => v.toInt().toString(),
        ),
        child: RangeSlider(
          values: _draggingYear ?? _yearValues(),
          min: _minYear.toDouble(),
          max: _maxYear.toDouble(),
          divisions: _maxYear - _minYear,
          onChanged: (v) => setState(() => _draggingYear = v),
          onChangeEnd: (v) {
            setState(() => _draggingYear = null);
            final lower = v.start.toInt();
            final upper = v.end.toInt();
            _emit(
              _f.copyWithYear(
                publishedYearLower: lower == _minYear ? null : lower,
                publishedYearUpper: upper == _maxYear ? null : upper,
              ),
            );
          },
        ),
      ),
      _Section(
        title: l10n.translate('licensed_status'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DesktopSegmented<bool?>(
            value: _f.isLicensed,
            segments: [
              (null, l10n.translate('any'), null),
              (true, l10n.translate('yes'), null),
              (false, l10n.translate('no'), null),
            ],
            onChanged: (v) => _emit(_f.copyWithIsLicensed(v)),
          ),
        ),
      ),
      _Section(
        title: l10n.translate('has_anime'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DesktopSegmented<bool?>(
            value: _f.hasAnime,
            segments: [
              (null, l10n.translate('any'), null),
              (true, l10n.translate('yes'), null),
              (false, l10n.translate('no'), null),
            ],
            onChanged: (v) => _emit(_f.copyWithHasAnime(v)),
          ),
        ),
      ),
      if (_f.staff.isNotEmpty || _f.publisher.isNotEmpty)
        _Section(
          title: l10n.translate('also_filtering_by'),
          child: _chipWrap([
            for (final s in _f.staff)
              _RemovableChip(
                label: s,
                onRemove: () => _emit(
                  _f.copyWith(staff: _f.staff.where((x) => x != s).toList()),
                ),
              ),
            for (final p in _f.publisher)
              _RemovableChip(
                label: p,
                onRemove: () => _emit(
                  _f.copyWith(
                    publisher: _f.publisher.where((x) => x != p).toList(),
                  ),
                ),
              ),
          ]),
        ),
    ];
  }

  RangeValues _yearValues() => RangeValues(
    (_f.publishedYearLower ?? _minYear).toDouble(),
    (_f.publishedYearUpper ?? _maxYear).toDouble(),
  );

  Widget _rangeLabel(RangeValues v, String Function(double) fmt) => Text(
    '${fmt(v.start)} – ${fmt(v.end)}',
    style: AppTypography.display(color: context.colors.accent, fontSize: 12.5),
  );

  Widget _chipWrap(List<Widget> chips) =>
      Wrap(spacing: 6, runSpacing: 6, children: chips);

  Widget _chip({
    required String label,
    required TriState state,
    required ValueChanged<TriState> onChanged,
  }) => DesktopTriChip(label: label, state: state, onChanged: onChanged);

  // ─── Genres ──────────────────────────────────────────────────────────────

  Widget _genreSection(LocalizationService l10n) {
    if (_genres.isEmpty) return _loadingLine();

    // Active genres always show, even when the list is collapsed past them.
    final active = _genres.where((g) {
      final v = g['value']?.toString() ?? '';
      return _f.genre.contains(v) || _f.genreNot.contains(v);
    });
    final visible = _showAllGenres
        ? _genres
        : {..._genres.take(_collapsedGenreCount), ...active}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipWrap([
          for (final g in visible)
            _chip(
              label: g['label']?.toString() ?? '',
              state: _stateOf(
                g['value']?.toString() ?? '',
                _f.genre,
                _f.genreNot,
              ),
              onChanged: (s) {
                final value = g['value']?.toString() ?? '';
                final (inc, exc) = _apply(value, s, _f.genre, _f.genreNot);
                _emit(_f.copyWith(genre: inc, genreNot: exc));
              },
            ),
        ]),
        if (_genres.length > _collapsedGenreCount) ...[
          const SizedBox(height: 8),
          _TextAction(
            label: _showAllGenres
                ? l10n.translate('show_less')
                : '${l10n.translate('show_all')} (${_genres.length})',
            onTap: () => setState(() => _showAllGenres = !_showAllGenres),
          ),
        ],
      ],
    );
  }

  // ─── Tags ────────────────────────────────────────────────────────────────

  String _tagValue(Map<String, dynamic> tag) => widget.tagsByName
      ? tag['name']?.toString() ?? ''
      : tag['id']?.toString() ?? '';

  String _tagLabel(String value) {
    if (widget.tagsByName) return value;
    final id = int.tryParse(value);
    return id == null ? value : getIt<MetadataService>().getTagName(id);
  }

  Widget _tagSection(LocalizationService l10n) {
    final selected = [
      for (final v in _f.tag) (v, TriState.include),
      for (final v in _f.tagNot) (v, TriState.exclude),
    ];

    final query = _tagQuery.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <Map<String, dynamic>>[]
        : _tags
              .where(
                (t) =>
                    (t['name']?.toString().toLowerCase() ?? '').contains(query),
              )
              .take(_maxTagMatches)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty) ...[
          _chipWrap([
            for (final (value, state) in selected)
              _chip(
                label: _tagLabel(value),
                state: state,
                onChanged: (s) {
                  final (inc, exc) = _apply(value, s, _f.tag, _f.tagNot);
                  _emit(_f.copyWith(tag: inc, tagNot: exc));
                },
              ),
          ]),
          const SizedBox(height: 10),
          if (_f.tag.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DesktopSegmented<String>(
                value: _f.tagMode,
                segments: [
                  ('and', l10n.translate('match_all'), null),
                  ('or', l10n.translate('match_any'), null),
                ],
                onChanged: (v) => _emit(_f.copyWith(tagMode: v)),
              ),
            ),
        ],
        _SearchBox(
          controller: _tagSearch,
          hint: l10n.translate('search_tags'),
          onChanged: (v) => setState(() => _tagQuery = v),
        ),
        if (query.isEmpty && _tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              l10n
                  .translate('tag_search_hint')
                  .replaceAll('{count}', '${_tags.length}'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        if (query.isNotEmpty) ...[
          const SizedBox(height: 6),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.translate('no_results'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          for (final tag in matches)
            _TagRow(
              name: tag['name']?.toString() ?? '',
              path: tag['name_path']?.toString(),
              state: _stateOf(_tagValue(tag), _f.tag, _f.tagNot),
              onChanged: (s) {
                final (inc, exc) = _apply(_tagValue(tag), s, _f.tag, _f.tagNot);
                _emit(_f.copyWith(tag: inc, tagNot: exc));
              },
            ),
        ],
      ],
    );
  }

  Widget _loadingLine() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LinearProgressIndicator(
      minHeight: 2,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// A collapsible titled block within the panel.
class _Section extends StatefulWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    if (widget.trailing != null && _open) widget.trailing!,
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _open ? 0 : -0.25,
                      duration: AppMotion.fast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _open
                ? widget.child
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A compact include/exclude chip for pointer use.
///
/// Click cycles off → include → exclude → off; right-click jumps straight to
/// exclude (or back to off), so excluding never takes two clicks.
class DesktopTriChip extends StatelessWidget {
  final String label;
  final TriState state;
  final ValueChanged<TriState> onChanged;

  const DesktopTriChip({
    super.key,
    required this.label,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData? icon) = switch (state) {
      TriState.include => (
        context.colors.accent.withValues(alpha: 0.18),
        context.colors.accent,
        Icons.check_rounded,
      ),
      TriState.exclude => (
        context.colors.error.withValues(alpha: 0.16),
        context.colors.error,
        Icons.remove_rounded,
      ),
      TriState.off => (
        context.colors.surface,
        context.colors.text.withValues(alpha: 0.82),
        null,
      ),
    };

    return DesktopHoverSurface(
      onTap: () => onChanged(switch (state) {
        TriState.off => TriState.include,
        TriState.include => TriState.exclude,
        TriState.exclude => TriState.off,
      }),
      onSecondaryTap: () => onChanged(
        state == TriState.exclude ? TriState.off : TriState.exclude,
      ),
      tooltip: LocalizationService().translate('tri_chip_hint'),
      idleColor: bg,
      hoverColor: state == TriState.off
          ? context.colors.surfaceRaised
          : bg.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 8, 6, 12, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.sans(
              color: fg,
              fontSize: 12.5,
              fontWeight: state == TriState.off
                  ? FontWeight.w500
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String name;
  final String? path;
  final TriState state;
  final ValueChanged<TriState> onChanged;

  const _TagRow({
    required this.name,
    required this.path,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // The path's last segment is the name itself; only the parents add
    // anything.
    final parents = (path ?? '').split('>').map((p) => p.trim()).toList();
    if (parents.isNotEmpty) parents.removeLast();
    final context_ = parents.where((p) => p.isNotEmpty).join(' › ');

    return DesktopHoverSurface(
      onTap: () => onChanged(
        state == TriState.include ? TriState.off : TriState.include,
      ),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sans(
                    color: state == TriState.off
                        ? context.colors.text
                        : (state == TriState.include
                              ? context.colors.accent
                              : context.colors.error),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (context_.isNotEmpty)
                  Text(
                    context_,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          _MiniToggle(
            icon: Icons.add_rounded,
            active: state == TriState.include,
            color: context.colors.accent,
            onTap: () => onChanged(
              state == TriState.include ? TriState.off : TriState.include,
            ),
          ),
          _MiniToggle(
            icon: Icons.remove_rounded,
            active: state == TriState.exclude,
            color: context.colors.error,
            onTap: () => onChanged(
              state == TriState.exclude ? TriState.off : TriState.exclude,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: active,
      selectedColor: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        size: 17,
        color: active ? color : context.colors.textMuted,
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onRemove,
      idleColor: context.colors.accent.withValues(alpha: 0.18),
      hoverColor: context.colors.error.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.close_rounded, size: 14, color: context.colors.text),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.display(
          color: context.colors.accent,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

/// A small filled search field used inside panels.
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.sans(color: context.colors.text, fontSize: 13.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: context.colors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: context.colors.textMuted,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.accent, width: 1.2),
        ),
      ),
    );
  }
}
