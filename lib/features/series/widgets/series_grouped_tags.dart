import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/widgets/series_tags_fade_out.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/tag_group.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_tag_group.dart';
import 'package:mangabaka_app/features/series/widgets/tags_placeholder.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Placeholder first, tags a frame later: hundreds of chips in the opening frame stalled it up to 1s.
class SeriesGroupedTags extends StatefulWidget {
  final Series series;
  final LocalizationService l10n;

  const SeriesGroupedTags({
    super.key,
    required this.series,
    required this.l10n,
  });

  @override
  State<SeriesGroupedTags> createState() => _SeriesGroupedTagsState();
}

class _SeriesGroupedTagsState extends State<SeriesGroupedTags> {
  /// Must comfortably overfill [_collapsedMaxHeight].
  static const int _collapsedChipBudget = 60;

  static const double _collapsedMaxHeight = 400.0;

  bool _tagsExpanded = false;

  List<TagGroup>? _groups;
  int _totalChips = 0;

  List<Widget>? _cachedContent;
  bool _cachedExpanded = false;
  SearchFilters? _lastDrawerFilters;

  final GlobalKey _contentKey = GlobalKey();
  bool _needsShowMore = false;
  double _contentHeight = 0.0;

  bool get _hasMore => _totalChips > _collapsedChipBudget || _needsShowMore;

  @override
  void initState() {
    super.initState();
    _scheduleResolve();
  }

  @override
  void didUpdateWidget(SeriesGroupedTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare contents: the network `fullSeries` swaps in a new Series with the same tags just after open.
    if (listEquals(widget.series.tags, oldWidget.series.tags)) return;
    _groups = null;
    _totalChips = 0;
    _cachedContent = null;
    _needsShowMore = false;
    _contentHeight = 0.0;
    _scheduleResolve();
  }

  /// Also waits out the push transition so the tag build lands on a frame where nothing animates.
  void _scheduleResolve() {
    if (widget.series.tags.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _groups != null) return;
      await SeriesDetailScreen.of(context)?.transitionSettled;
      if (!mounted || _groups != null) return;
      setState(() {
        _groups = TagGrouping.resolve(
          widget.series.tags,
          getIt<MetadataService>(),
        );
        _totalChips = widget.series.tags.length;
        _cachedContent = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
    });
  }

  /// Chip widths vary, so overflowing the collapsed clip is only known after layout.
  void _measureContent() {
    if (!mounted) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final height = box.size.height;
    final needsShowMore = height > _collapsedMaxHeight;
    if (needsShowMore == _needsShowMore && height == _contentHeight) return;
    setState(() {
      _needsShowMore = needsShowMore;
      _contentHeight = height;
    });
  }

  /// While the filter drawer is open a tap toggles the tag instead of navigating away to a search.
  void _handleTagTap(String tag) {
    final state = SeriesDetailScreen.of(context);
    if (state == null) return;
    if (state.drawerFilters != null) {
      state.handleTagLongPress(tag);
    } else {
      state.handleTagTap(tag);
    }
  }

  void _handleTagLongPress(String tag) =>
      SeriesDetailScreen.of(context)?.handleTagLongPress(tag);

  void _ensureContent() {
    final filters = SeriesDetailScreen.of(context)?.drawerFilters;
    if (filters != _lastDrawerFilters || _cachedExpanded != _tagsExpanded) {
      _cachedContent = null;
      _lastDrawerFilters = filters;
      _cachedExpanded = _tagsExpanded;
    }
    if (_cachedContent != null) return;

    final selectedTagIds = filters?.tag.toSet() ?? const <String>{};
    final groups = _tagsExpanded || _totalChips <= _collapsedChipBudget
        ? _groups!
        : TagGrouping.trimTo(_groups!, _collapsedChipBudget);

    _cachedContent = [
      for (final group in groups)
        SeriesTagGroup(
          header: group.header,
          subGroups: group.subGroups,
          selectedTagIds: selectedTagIds,
          onTagTap: _handleTagTap,
          onTagLongPress: _handleTagLongPress,
          onToggle: () => WidgetsBinding.instance.addPostFrameCallback(
            (_) => _measureContent(),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    if (_groups == null) {
      return _card(const TagsPlaceholder());
    }

    _ensureContent();

    return LayoutBuilder(
      builder: (context, constraints) {
        // A width change can reflow the chips into a different number of rows.
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _clippedContent(),
              if (_hasMore) ...[
                const SizedBox(height: 12),
                Center(child: _showMoreButton()),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _card(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: MbCard(
      label: widget.l10n.translate('tags'),
      onHeaderTap: _groups != null && (_hasMore || _tagsExpanded)
          ? () => setState(() => _tagsExpanded = !_tagsExpanded)
          : null,
      child: child,
    ),
  );

  Widget _clippedContent() {
    final isClipped = _needsShowMore && !_tagsExpanded;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: isClipped
            ? const BoxConstraints(maxHeight: _collapsedMaxHeight)
            : const BoxConstraints(),
        child: ClipRect(
          child: Stack(
            children: [
              SingleChildScrollView(
                // Never scrolls: it only lets the content exceed the clip without an overflow error.
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _cachedContent!,
                ),
              ),
              if (isClipped) const SeriesTagsFadeOut(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showMoreButton() {
    return InkWell(
      onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.l10n.translate(
                _tagsExpanded ? 'show_less' : 'show_all_tags',
              ),
              style: AppTypography.sans(
                color: context.colors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _tagsExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: context.colors.accent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
