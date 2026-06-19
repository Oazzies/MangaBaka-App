import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

class SeriesTagGroup extends StatefulWidget {
  final String header;
  final Map<String, List<String>> subGroups;
  final VoidCallback? onToggle;

  const SeriesTagGroup({
    super.key,
    required this.header,
    required this.subGroups,
    this.onToggle,
  });

  @override
  State<SeriesTagGroup> createState() => _SeriesTagGroupState();
}

class _SeriesTagGroupState extends State<SeriesTagGroup> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
        widget.onToggle?.call();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppConstants.accentColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.header.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textMutedColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    _isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 16,
                    color: AppConstants.textMutedColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isCollapsed
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            ...widget.subGroups.entries.map((subEntry) {
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
                                    children: tags.map((tag) => _buildTagChip(tag)).toList(),
                                  ),
                                  if (subEntry.key != widget.subGroups.keys.last)
                                    const SizedBox(height: 16),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final metadataService = getIt<MetadataService>();
    final path = metadataService.getTagPath(tag) ?? tag;
    final parts = path.split(' > ');
    
    String displayName = tag;
    if (parts.length >= 2) {
      if (parts.length == 2) {
        displayName = parts[1];
      } else if (parts.length == 3) {
        displayName = parts[2];
      } else {
        displayName = parts.sublist(2).join(' > ');
      }
    }

    final tagParts = displayName.split(' > ');

    final detailState = SeriesDetailScreen.of(context);
    final tagId = metadataService.getTagId(tag) ?? tag;
    final isSelected = detailState?.drawerFilters?.tag.contains(tagId) ?? false;

    return ChipBase(
      borderRadius: AppConstants.pillRadius,
      backgroundColor: isSelected
          ? AppConstants.accentColor
          : AppConstants.secondaryBackground,
      borderColor: isSelected
          ? AppConstants.accentColor
          : AppConstants.borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      onTap: () {
        final isSelecting = detailState?.drawerFilters != null;
        if (isSelecting) {
          detailState?.handleTagLongPress(tag);
        } else {
          detailState?.handleTagTap(tag);
        }
      },
      onLongPress: () => detailState?.handleTagLongPress(tag),
      label: Text.rich(
        TextSpan(
          children: [
            if (tagParts.length > 1) ...[
              TextSpan(
                text: '${tagParts.sublist(0, tagParts.length - 1).join(' > ')} > ',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : AppConstants.textMutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ],
            TextSpan(
              text: tagParts.last,
              style: TextStyle(
                color: isSelected ? Colors.white : AppConstants.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
