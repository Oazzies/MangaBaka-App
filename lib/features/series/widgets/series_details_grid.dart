import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_link.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/series_grouped_tags.dart';
import 'package:mangabaka_app/features/series/widgets/external_ratings_section.dart';
import 'package:mangabaka_app/features/series/widgets/state_selection_section.dart';
import 'package:mangabaka_app/features/series/widgets/rating_icon_button.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SeriesDetailsGrid extends StatefulWidget {
  final Series series;
  final List<SeriesLink>? enrichedLinks;
  final LibraryEntry? entry;
  final bool isWide;
  final LocalizationService l10n;
  final double horizontalPadding;
  final Function(String)? onAuthorTap;
  final Function(String)? onPublisherTap;
  final VoidCallback? onAddToLibrary;
  final bool isInLibrary;
  final String? status;
  final List<Series>? relatedSeries;
  final Function(String)? onStateChanged;
  final Function(int)? onRatingChanged;
  final VoidCallback? onUpdateChapter;
  final VoidCallback? onUpdateVolume;

  const SeriesDetailsGrid({
    super.key,
    required this.series,
    this.enrichedLinks,
    this.entry,
    this.isWide = false,
    required this.l10n,
    this.horizontalPadding = 16.0,
    this.onAuthorTap,
    this.onPublisherTap,
    this.onAddToLibrary,
    this.isInLibrary = false,
    this.status,
    this.relatedSeries,
    this.onStateChanged,
    this.onRatingChanged,
    this.onUpdateChapter,
    this.onUpdateVolume,
  });

  @override
  State<SeriesDetailsGrid> createState() => _SeriesDetailsGridState();
}

class _SeriesDetailsGridState extends State<SeriesDetailsGrid> {
  bool _showFullDescription = false;

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'releasing': return AppConstants.successColor;
      case 'completed': return AppConstants.infoColor;
      case 'hiatus': return AppConstants.warningColor;
      default: return AppConstants.textMutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.series;
    final ds = widget.status ?? s.status;
    final isLongDesc = s.description.length > 200;
    final hasRelated = widget.relatedSeries != null && widget.relatedSeries!.isNotEmpty;
    final hasGenres = s.genres.isNotEmpty;
    final hasArtists = s.artists.isNotEmpty;
    final hasPublishers = s.publishers.isNotEmpty;
    final hasLinks = (widget.enrichedLinks != null && widget.enrichedLinks!.isNotEmpty) || s.links.isNotEmpty;
    final hasStaff = s.authors.isNotEmpty || hasArtists || hasPublishers;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _badgeRow(s.type, ds),
          const SizedBox(height: 12),
          Text(s.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.1, color: AppConstants.textColor)),
          if (s.nativeTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(s.nativeTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppConstants.textMutedColor)),
          ],
          const SizedBox(height: 20),
          _metadataRow(s),
          const SizedBox(height: 20),
          if (!widget.isInLibrary && widget.onAddToLibrary != null) _libraryBtn(),
          if (widget.isInLibrary) _buildActionBar(),
          const SizedBox(height: 20),
          ExternalRatingsSection(series: s),
          const SizedBox(height: 24),
          if (s.description.isNotEmpty) _synopsisSection(s.description, isLongDesc),
          if (hasGenres) ...[
            const SizedBox(height: 24),
            _secHdr('GENRES'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: s.genres.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppConstants.tertiaryBackground, borderRadius: BorderRadius.circular(AppConstants.pillRadius)),
              child: Text(g, style: TextStyle(fontSize: 13, color: AppConstants.textColor)),
            )).toList()),
          ],
          if (s.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            SeriesGroupedTags(series: s, l10n: widget.l10n),
          ],
          if (hasStaff) ...[
            const SizedBox(height: 24),
            _secHdr('STAFF'),
            const SizedBox(height: 12),
            if (s.authors.isNotEmpty) _chipRow('Authors', s.authors, widget.onAuthorTap),
            if (hasArtists) ...[const SizedBox(height: 10), _chipRow('Artists', s.artists, widget.onAuthorTap)],
            if (hasPublishers) ...[const SizedBox(height: 10), _chipRow('Publishers', s.publishers, widget.onPublisherTap)],
          ],
          if (hasLinks) ...[
            const SizedBox(height: 24),
            _secHdr('LINKS'),
            const SizedBox(height: 10),
            _linksList(s),
          ],
          if (hasRelated) ...[
            const SizedBox(height: 24),
            _secHdr('ADAPTATIONS & INTERCONNECTIONS'),
            const SizedBox(height: 12),
            ...widget.relatedSeries!.map(_relatedCard),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final e = widget.entry;
    if (e == null) return const SizedBox.shrink();
    final hasChapters = widget.series.totalChapters.isNotEmpty && widget.series.totalChapters != 'null';
    final hasVolumes = widget.series.finalVolume.isNotEmpty && widget.series.finalVolume != 'null';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StateSelectionSection(
                  currentState: e.state,
                  onStateChanged: (s) => widget.onStateChanged?.call(s),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onRatingChanged != null)
                RatingIconButton(
                  currentRating: e.rating,
                  onRatingChanged: (r) => widget.onRatingChanged?.call(r),
                ),
            ],
          ),
          if (hasChapters || hasVolumes) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasChapters) Expanded(child: _progressBtn('Chapters', e.progressChapter ?? 0, widget.series.totalChapters, widget.onUpdateChapter)),
                if (hasChapters && hasVolumes) const SizedBox(width: 12),
                if (hasVolumes) Expanded(child: _progressBtn('Volumes', e.progressVolume ?? 0, widget.series.finalVolume, widget.onUpdateVolume)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressBtn(String label, int value, String total, VoidCallback? onTap) {
    final displayTotal = (total.isEmpty || total == 'null') ? '?' : total;
    return Material(
      color: AppConstants.tertiaryBackground,
      borderRadius: BorderRadius.circular(AppConstants.denseRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 18, color: AppConstants.accentColor),
              const SizedBox(width: 8),
              Expanded(child: Text('$value / $displayTotal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textColor), overflow: TextOverflow.ellipsis)),
              Icon(Icons.add, size: 18, color: AppConstants.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secHdr(String t) => Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textMutedColor, letterSpacing: 1.0));

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppConstants.pillRadius)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg, letterSpacing: 0.5)),
  );

  Widget _badgeRow(String type, String? status) => Row(
    children: [
      _badge(type.toUpperCase(), AppConstants.tertiaryBackground, AppConstants.textColor),
      const SizedBox(width: 8),
      _badge(status?.toUpperCase() ?? '', _statusColor(status).withValues(alpha: 0.2), _statusColor(status)),
    ],
  );

  Widget _metadataRow(Series s) {
    final avg = s.combinedAverage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppConstants.secondaryBackground, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _metaCell('Author', s.authors.isNotEmpty ? s.authors.first : '-'),
          _gap(),
          _metaCell('Chapters', s.totalChapters.isNotEmpty ? s.totalChapters : '-'),
          _gap(),
          _metaCell('Score', avg != null ? avg.toStringAsFixed(1) : (s.rating.isNotEmpty ? s.rating : '-'), showStar: true),
        ],
      ),
    );
  }

  Widget _gap() => Container(width: 1, height: 32, color: AppConstants.tertiaryBackground);

  Widget _metaCell(String label, String value, {bool showStar = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.textMutedColor, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (showStar) const Icon(Icons.star, size: 14, color: Color(0xFFffc83e)),
            if (showStar) const SizedBox(width: 4),
            Flexible(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textColor), overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }

  Widget _libraryBtn() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.accentColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAddToLibrary,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: Text('Add to Library', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.primaryBackground))),
          ),
        ),
      ),
    );
  }

  Widget _synopsisSection(String description, bool isLongDesc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secHdr('SYNOPSIS'),
      const SizedBox(height: 8),
      Text(description, style: TextStyle(fontSize: 14, color: AppConstants.textColor.withValues(alpha: 0.9), height: 1.7),
        maxLines: _showFullDescription ? null : 6, overflow: _showFullDescription ? null : TextOverflow.ellipsis),
      if (isLongDesc)
        GestureDetector(
          onTap: () => setState(() => _showFullDescription = !_showFullDescription),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_showFullDescription ? 'Show less' : 'Read more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.accentColor)),
          ),
        ),
    ]);
  }

  Widget _chipRow(String label, List<String> items, Function(String)? onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textMutedColor)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: items.map((name) => GestureDetector(
        onTap: onTap != null ? () => onTap(name) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppConstants.tertiaryBackground, borderRadius: BorderRadius.circular(AppConstants.pillRadius)),
          child: Text(name, style: TextStyle(fontSize: 13, color: AppConstants.textColor, fontWeight: FontWeight.w500)),
        ),
      )).toList()),
    ]);
  }

  Widget _linksList(Series s) {
    final allLinks = <Widget>[];
    final processed = <String>{};

    if (widget.enrichedLinks != null) {
      for (final link in widget.enrichedLinks!) {
        final url = link.url;
        if (url.isNotEmpty && processed.add(url)) {
          allLinks.add(_linkTile(link.nameDisplay.isNotEmpty ? link.nameDisplay : link.name, url));
        }
      }
    }
    for (final link in s.links) {
      String url = '';
      String label = '';
      if (link is String) {
        url = link;
        label = link;
      } else if (link is Map) {
        url = link['url']?.toString() ?? '';
        label = link['label']?.toString() ?? link['name']?.toString() ?? url;
      }
      if (url.isNotEmpty && processed.add(url)) {
        allLinks.add(_linkTile(label, url));
      }
    }

    if (allLinks.isEmpty) return const SizedBox.shrink();
    return Column(children: allLinks);
  }

  Widget _linkTile(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppConstants.tertiaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: AppConstants.textColor), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Icon(Icons.open_in_new, size: 14, color: AppConstants.textMutedColor),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _relatedCard(Series rel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppConstants.secondaryBackground, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: WidgetUtils.networkImage(url: rel.coverUrl, width: 40, height: 56, fit: BoxFit.cover, memCacheWidth: 120),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(rel.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.textColor))),
            _badge(rel.type.toUpperCase(), AppConstants.tertiaryBackground, AppConstants.textColor),
          ],
        ),
      ),
    );
  }
}
