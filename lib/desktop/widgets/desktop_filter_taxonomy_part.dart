part of 'desktop_filter_panel.dart';

extension _DesktopFilterTaxonomy on _DesktopFilterPanelState {
  Widget _genreSection(LocalizationService l10n) {
    if (_genres.isEmpty) return _loadingLine();

    final active = _genres.where((g) {
      final v = g['value']?.toString() ?? '';
      return _f.genre.contains(v) || _f.genreNot.contains(v);
    });
    final visible = _showAllGenres
        ? _genres
        : {
            ..._genres.take(_DesktopFilterPanelState._collapsedGenreCount),
            ...active,
          }.toList();

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
        if (_genres.length > _DesktopFilterPanelState._collapsedGenreCount) ...[
          const SizedBox(height: 8),
          _TextAction(
            label: _showAllGenres
                ? l10n.translate('show_less')
                : '${l10n.translate('show_all')} (${_genres.length})',
            onTap: () => _updateState(() => _showAllGenres = !_showAllGenres),
          ),
        ],
      ],
    );
  }

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

    final preparedQuery = SearchUtils.prepare(_tagQuery);
    final matches = preparedQuery.isEmpty
        ? const <Map<String, dynamic>>[]
        : _tags
              .where((t) => preparedQuery.matches(t['name']?.toString() ?? ''))
              .take(_DesktopFilterPanelState._maxTagMatches)
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
          onChanged: (v) => _updateState(() => _tagQuery = v),
        ),
        if (preparedQuery.isEmpty && _tags.isNotEmpty)
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
        if (!preparedQuery.isEmpty) ...[
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
}
