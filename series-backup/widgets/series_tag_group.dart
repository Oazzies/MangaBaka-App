import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';

class SeriesTagGroup extends StatelessWidget {
  final String header;
  final Map<String, List<String>> subGroups;

  const SeriesTagGroup({
    super.key,
    required this.header,
    required this.subGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  ...subGroups.entries.map((subEntry) {
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
                        if (subEntry.key != subGroups.keys.last) const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final tagParts = tag.split(' > ');
    return ChipBase(
      label: Text.rich(
        TextSpan(
          children: [
            if (tagParts.length > 1) ...[
              TextSpan(
                text: '${tagParts.sublist(0, tagParts.length - 1).join(' > ')} > ',
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
  }
}
