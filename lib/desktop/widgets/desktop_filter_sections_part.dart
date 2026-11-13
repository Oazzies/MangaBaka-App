part of 'desktop_filter_panel.dart';

extension _DesktopFilterSections on _DesktopFilterPanelState {
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
      _Section(
        title: l10n.translate('content_rating'),
        child: _chipWrap([
          for (final r in ContentRatingFilter.all)
            _chip(
              label: l10n.translate(r),
              state: _stateOf(r, _f.contentRating, _f.contentRatingNot),
              onChanged: (s) {
                final (inc, exc) = _apply(
                  r,
                  s,
                  _f.contentRating,
                  _f.contentRatingNot,
                );
                _emit(_f.copyWith(contentRating: inc, contentRatingNot: exc));
              },
            ),
        ]),
      ),
      _Section(
        title: l10n.translate('genres'),
        child: _genreSection(l10n),
      ),
      _Section(
        title: l10n.translate('tags'),
        child: _tagSection(l10n),
      ),
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
          divisions: SettingsManager().ratingSliderStep.divisions,
          onChanged: (v) {
            final step = SettingsManager().ratingSliderStep.stepValue;
            final start = ((v.start / step).round() * step)
                .toDouble()
                .clamp(0.0, 100.0);
            final end = ((v.end / step).round() * step)
                .toDouble()
                .clamp(0.0, 100.0);
            _updateState(() => _draggingRating = RangeValues(start, end));
          },
          onChangeEnd: (v) {
            final step = SettingsManager().ratingSliderStep.stepValue;
            final start = ((v.start / step).round() * step)
                .toDouble()
                .clamp(0.0, 100.0);
            final end = ((v.end / step).round() * step)
                .toDouble()
                .clamp(0.0, 100.0);
            _updateState(() => _draggingRating = null);
            _emit(_f.copyWith(ratingLower: start, ratingUpper: end));
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
          min: _DesktopFilterPanelState._minYear.toDouble(),
          max: _DesktopFilterPanelState._maxYear.toDouble(),
          divisions:
              _DesktopFilterPanelState._maxYear -
              _DesktopFilterPanelState._minYear,
          onChanged: (v) => _updateState(() => _draggingYear = v),
          onChangeEnd: (v) {
            _updateState(() => _draggingYear = null);
            final lower = v.start.toInt();
            final upper = v.end.toInt();
            _emit(
              _f.copyWithYear(
                publishedYearLower: lower == _DesktopFilterPanelState._minYear
                    ? null
                    : lower,
                publishedYearUpper: upper == _DesktopFilterPanelState._maxYear
                    ? null
                    : upper,
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
      _Section(
        title: l10n.translate('filter_publisher'),
        child: _PublisherField(
          hint: l10n.translate('filter_publisher_hint'),
          onSubmit: (name) {
            if (name.isEmpty || _f.publisher.contains(name)) return;
            _emit(_f.copyWith(publisher: [..._f.publisher, name]));
          },
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
    (_f.publishedYearLower ?? _DesktopFilterPanelState._minYear).toDouble(),
    (_f.publishedYearUpper ?? _DesktopFilterPanelState._maxYear).toDouble(),
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

  Widget _loadingLine() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LinearProgressIndicator(
      minHeight: 2,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
