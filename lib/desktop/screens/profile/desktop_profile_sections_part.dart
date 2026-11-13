part of 'desktop_profile_screen.dart';

extension _DesktopProfileSections on DesktopProfileScreenState {
  /// Everything but the overview: identity, standout picks, recent activity.
  /// With [inline] the overview is included too, after the identity card.
  Widget _mainColumn(LocalizationService l10n, {required bool inline}) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        DesktopTokens.pagePadding,
        0,
        // Beside the sidebar the gutter between the two is the sidebar's; on
        // its own the column keeps the page's right gutter.
        inline ? DesktopTokens.pagePadding : DesktopTokens.pagePadding * 0.75,
        48,
      ),
      children: [
        _IdentityCard(
          name: _displayName(l10n),
          username: profile!.preferredUsername,
          role: profile!.role,
          avatarUrl: profile!.avatarUrl,
          onLogout: _logout,
        ),
        const SizedBox(height: 16),
        const MyStacksEntryCard(),
        if (inline) ...[
          const SizedBox(height: DesktopTokens.sectionGap),
          _overview(l10n, twoColumns: true),
          if (_topPublishers.isNotEmpty) ...[
            const SizedBox(height: DesktopTokens.sectionGap),
            _publishersCard(l10n),
          ],
        ],
        if (_highestRated != null || _mostReread != null) ...[
          const SizedBox(height: DesktopTokens.sectionGap),
          DesktopSectionTitle(title: l10n.translate('standout_picks')),
          _standouts(l10n),
        ],
        const SizedBox(height: DesktopTokens.sectionGap),
        _activity(
          l10n.translate('recently_changed'),
          recentlyChanged,
          onNearEnd: fetchRecentlyChanged,
          loading: isLoadingChanged && recentlyChanged.isEmpty,
        ),
        const SizedBox(height: DesktopTokens.sectionGap),
        _activity(
          l10n.translate('recently_added'),
          recentlyAdded,
          onNearEnd: fetchRecentlyAdded,
          loading: isLoadingAdded && recentlyAdded.isEmpty,
        ),
      ],
    );
  }

  String _displayName(LocalizationService l10n) {
    final p = profile!;
    if (p.nickname?.isNotEmpty == true) return p.nickname!;
    if (p.preferredUsername?.isNotEmpty == true) return p.preferredUsername!;
    return l10n.translate('your_profile');
  }

  /// The reading overview as one card of labelled figures.
  Widget _overview(LocalizationService l10n, {bool twoColumns = false}) {
    final rows = [
      (
        Icons.book_rounded,
        l10n.translate('total_series'),
        NumberUtils.formatCount(totalSeries),
      ),
      (
        Icons.article_rounded,
        l10n.translate('chapters_read'),
        NumberUtils.formatCount(chaptersRead),
      ),
      (
        Icons.library_books_rounded,
        l10n.translate('volumes_read'),
        NumberUtils.formatCount(volumesRead),
      ),
      (
        Icons.star_rounded,
        l10n.translate('mean_score'),
        meanScore.toStringAsFixed(1),
      ),
      (
        Icons.check_circle_rounded,
        l10n.translate('completion'),
        '${_completionRate.toStringAsFixed(1)}%',
      ),
      (
        Icons.flag_rounded,
        l10n.translate('finish_rate'),
        '${_finishRate.toStringAsFixed(1)}%',
      ),
      (
        Icons.replay_rounded,
        l10n.translate('total_rereads'),
        NumberUtils.formatCount(_totalRereads),
      ),
    ];

    Widget column(List<(IconData, String, String)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: context.colors.border),
          _OverviewRow(
            icon: items[i].$1,
            label: items[i].$2,
            value: items[i].$3,
          ),
        ],
      ],
    );

    final split = (rows.length + 1) ~/ 2;

    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSectionTitle(
            title: l10n.translate('reading_stats'),
            padding: const EdgeInsets.only(bottom: 6),
          ),
          if (twoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(rows.sublist(0, split))),
                const SizedBox(width: 40),
                Expanded(child: column(rows.sublist(split))),
              ],
            )
          else
            column(rows),
        ],
      ),
    );
  }

  /// The publishers behind most of the library, as hover rows with a bar
  /// scaled to the biggest. Tapping one opens its publisher page.
  Widget _publishersCard(LocalizationService l10n) {
    final max = _topPublishers.first.count;
    return DesktopCard(
      showBorder: false,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopSectionTitle(
            title: l10n.translate('library_your_publishers'),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          ),
          for (final p in _topPublishers)
            DesktopHoverSurface(
              onTap: () => openPublisherByName(context, p.name),
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.sans(
                            color: context.colors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n
                            .translate('library_publishers_series')
                            .replaceAll('{count}', '${p.count}'),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : p.count / max,
                      minHeight: 5,
                      backgroundColor: context.colors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(context.colors.accent),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _standouts(LocalizationService l10n) {
    final cards = <Widget>[
      if (_highestRated != null)
        _StandoutCard(
          entry: _highestRated!,
          label: l10n.translate('highest_rated'),
          icon: Icons.star_rounded,
          value:
              '${l10n.translate('score')}: ${_highestRated!.libraryEntry.rating ?? 0}',
        ),
      if (_mostReread != null)
        _StandoutCard(
          entry: _mostReread!,
          label: l10n.translate('most_reread'),
          icon: Icons.replay_rounded,
          value:
              '${_mostReread!.libraryEntry.numberOfRereads} ${l10n.translate('rereads')}',
        ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
        if (cards.length == 1) const Spacer(),
      ],
    );
  }

  Widget _activity(
    String title,
    List<LibraryEntry> entries, {
    required VoidCallback onNearEnd,
    required bool loading,
  }) {
    if (!loading && entries.isEmpty) return const SizedBox.shrink();
    final textArea = DesktopCoverCard.textAreaHeight(context);
    return DesktopCarousel(
      title: title,
      loading: loading,
      itemCount: entries.length,
      itemWidth: 130,
      stretch: true,
      itemHeight: (width) => width * 1.5 + textArea,
      onNearEnd: onNearEnd,
      itemBuilder: (context, i) => DesktopCoverCard(
        series: entries[i].series,
        heroTag: 'profile_${title}_$i',
        caption: LocalizationService().translate(entries[i].state),
      ),
    );
  }
}
