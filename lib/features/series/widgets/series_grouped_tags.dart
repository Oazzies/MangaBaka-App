import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/widgets/series_tag_group.dart';
import 'package:mangabaka_app/features/series/widgets/mb_card.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

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
  bool _tagsExpanded = false;
  Map<String, Map<String, List<String>>>? _cachedGrouped;
  List<Widget>? _cachedContent;
  
  final GlobalKey _contentKey = GlobalKey();
  bool _needsShowMore = false;
  double _contentHeight = 0.0;
  SearchFilters? _lastDrawerFilters;

  void _measureContent() {
    if (!mounted) return;
    final renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      final needsShowMore = height > 400.0;
      if (needsShowMore != _needsShowMore || height != _contentHeight) {
        setState(() {
          _needsShowMore = needsShowMore;
          _contentHeight = height;
        });
      }
    }
  }

  void _ensureGrouped() {
    final detailState = SeriesDetailScreen.of(context);
    final currentFilters = detailState?.drawerFilters;
    if (currentFilters != _lastDrawerFilters) {
      _cachedContent = null;
      _lastDrawerFilters = currentFilters;
    }

    if (_cachedGrouped != null && _cachedContent != null) return;

    final metadataService = getIt<MetadataService>();
    final Map<String, Map<String, List<String>>> grouped = {};

    if (_cachedGrouped == null) {
      for (var tag in widget.series.tags) {
        final path = metadataService.getTagPath(tag) ?? tag;
        final parts = path.split(' > ');

        String header = 'Other';
        String subheader = '';

        if (parts.length >= 2) {
          header = parts[0];
          if (parts.length >= 3) {
            subheader = parts[1];
          }
        }

        grouped.putIfAbsent(header, () => {});
        grouped[header]!.putIfAbsent(subheader, () => []);
        grouped[header]![subheader]!.add(tag);
      }
      _cachedGrouped = grouped;
    }

    final sortedHeaders = _cachedGrouped!.keys.toList()..sort();

    _cachedContent = sortedHeaders.map((header) {
      return SeriesTagGroup(
        header: header,
        subGroups: _cachedGrouped![header]!,
        onToggle: () {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(SeriesGroupedTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.series.tags != oldWidget.series.tags) {
      _cachedGrouped = null;
      _cachedContent = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    _ensureGrouped();

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: MbCard(
            label: widget.l10n.translate('tags'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: _needsShowMore && !_tagsExpanded
                        ? const BoxConstraints(maxHeight: 400)
                        : const BoxConstraints(),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              key: _contentKey,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _cachedContent!,
                            ),
                          ),
                          if (!_tagsExpanded && _needsShowMore)
                            Positioned(
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
                                      AppConstants.secondaryBackground.withValues(alpha: 0),
                                      AppConstants.secondaryBackground,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_needsShowMore) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tagsExpanded ? widget.l10n.translate('show_less') : widget.l10n.translate('show_all_tags'),
                              style: TextStyle(
                                color: AppConstants.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _tagsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppConstants.accentColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
