import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
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

/// The tags card on the series detail page.
///
/// Tags are the heaviest part of that page — a well-tagged series carries a
/// couple of hundred chips, each of which has to be resolved through
/// [MetadataService] and laid out as rich text. Doing that in the same frame
/// as the rest of the page is what made opening a series feel like a stall of
/// up to a second, while untagged series opened instantly.
///
/// So this widget draws in two passes: the first frame gets a cheap
/// placeholder card, and the tags themselves are resolved and built on the
/// following frame. The page is on screen before any tag work starts.
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
  /// How many chips the collapsed card is allowed to build. Comfortably more
  /// than fills [_collapsedMaxHeight] — see [TagGrouping.trimTo].
  static const int _collapsedChipBudget = 60;

  /// Height the collapsed card clips to, about a dozen rows of chips.
  static const double _collapsedMaxHeight = 400.0;

  bool _tagsExpanded = false;

  /// Resolved tag data. Null until the deferred second pass has run.
  List<TagGroup>? _groups;
  int _totalChips = 0;

  /// Built chip groups, rebuilt only when the selection or the expanded state
  /// actually changes — not on every parent rebuild.
  List<Widget>? _cachedContent;
  bool _cachedExpanded = false;
  SearchFilters? _lastDrawerFilters;

  final GlobalKey _contentKey = GlobalKey();
  bool _needsShowMore = false;
  double _contentHeight = 0.0;

  /// True when the collapsed card cannot show everything — either because the
  /// budget trimmed it, or because what did fit still overflows the clip.
  bool get _hasMore => _totalChips > _collapsedChipBudget || _needsShowMore;

  @override
  void initState() {
    super.initState();
    _scheduleResolve();
  }

  @override
  void didUpdateWidget(SeriesGroupedTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare contents, not list identity: the network `fullSeries` swaps in a
    // fresh Series a moment after open, and its tags are almost always the
    // same ones we already resolved.
    if (listEquals(widget.series.tags, oldWidget.series.tags)) return;
    _groups = null;
    _totalChips = 0;
    _cachedContent = null;
    _needsShowMore = false;
    _contentHeight = 0.0;
    _scheduleResolve();
  }

  /// Hands the current frame back to the framework, then resolves the tags.
  ///
  /// On a phone this card starts below the fold, so it also waits out the push
  /// transition: the page is fully readable while it slides, and the tag build
  /// lands on a frame where nothing is animating.
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

  /// Measures the built chips to find out whether they overflow the collapsed
  /// clip — the budget bounds the count, but chip widths vary, so whether the
  /// result actually overflows can only be known after layout.
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

  /// Tapping a chip normally runs a search for it — but while the filter
  /// drawer is open it toggles the tag in the drawer instead, so building a
  /// filter set does not keep navigating away.
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
          // Expanding a subgroup changes the height, so the overflow check has
          // to run again.
          onToggle: () => WidgetsBinding.instance.addPostFrameCallback(
            (_) => _measureContent(),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    // First pass: the page draws without paying for any tag work.
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
    child: MbCard(label: widget.l10n.translate('tags'), child: child),
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
                // Not scrollable: the scroll view is here only so the content
                // can exceed the clip without overflowing.
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _cachedContent!,
                ),
              ),
              // Fades the cut-off row out rather than slicing it, so the clip
              // reads as "there is more" instead of as a rendering fault.
              if (isClipped) const _FadeOut(),
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

class _FadeOut extends StatelessWidget {
  const _FadeOut();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.surface.withValues(alpha: 0),
              context.colors.surface,
            ],
          ),
        ),
      ),
    );
  }
}
