import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/features/series/services/metadata_service.dart';
import 'package:bakahyou/features/series/widgets/chip.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.series.tags.isEmpty) return const SizedBox.shrink();

    final metadataService = getIt<MetadataService>();
    final Map<String, Map<String, List<String>>> grouped = {};

    for (var tag in widget.series.tags) {
      final path = metadataService.getTagPath(tag) ?? tag;
      final parts = path.split(' > ');

      String header = 'Other';
      String subheader = '';
      String tagName = tag;

      if (parts.length >= 2) {
        header = parts[0];
        if (parts.length == 2) {
          tagName = parts[1];
        } else if (parts.length == 3) {
          subheader = parts[1];
          tagName = parts[2];
        } else if (parts.length >= 4) {
          subheader = parts[1];
          tagName = parts.sublist(2).join(' > ');
        }
      }

      grouped.putIfAbsent(header, () => {});
      grouped[header]!.putIfAbsent(subheader, () => []);
      grouped[header]![subheader]!.add(tagName);
    }

    final contentWidgets = <Widget>[];
    final sortedHeaders = grouped.keys.toList()..sort();

    for (var header in sortedHeaders) {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        header.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.textMutedColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...grouped[header]!.entries.map((subEntry) {
                        final subheader = subEntry.key;
                        final tags = subEntry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subheader.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  subheader,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.textMutedColor,
                                  ),
                                ),
                              ),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) {
                                final tagParts = tag.split(' > ');
                                return ChipBase(
                                  label: Text.rich(
                                    TextSpan(
                                      children: [
                                        if (tagParts.length > 1) ...[
                                          TextSpan(
                                            text: tagParts
                                                    .sublist(
                                                        0, tagParts.length - 1)
                                                    .join(' > ') +
                                                ' > ',
                                            style: TextStyle(
                                              color: AppConstants.textMutedColor,
                                              fontSize: 12,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                        TextSpan(
                                          text: tagParts.last,
                                          style: TextStyle(
                                            color: AppConstants.textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (subEntry.key != grouped[header]!.keys.last)
                              const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalTags = widget.series.tags.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(widget.l10n.translate('tags')),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: _tagsExpanded
                ? const BoxConstraints()
                : const BoxConstraints(maxHeight: 400),
            child: ClipRect(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: contentWidgets,
                    ),
                  ),
                  if (!_tagsExpanded && totalTags > 15)
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
                              AppConstants.primaryBackground.withValues(alpha: 0),
                              AppConstants.primaryBackground,
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
        if (totalTags > 15)
          Center(
            child: InkWell(
              onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                      _tagsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppConstants.accentColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
