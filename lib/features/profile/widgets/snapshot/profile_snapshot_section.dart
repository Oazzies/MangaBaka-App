import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/snapshot/snapshot_list.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ProfileSnapshotSection extends StatelessWidget {
  final List<LibraryEntry> recentlyChanged;
  final bool hasMoreChanged;
  final VoidCallback onFetchMoreChanged;
  final List<LibraryEntry> recentlyAdded;
  final bool hasMoreAdded;
  final VoidCallback onFetchMoreAdded;

  const ProfileSnapshotSection({
    super.key,
    required this.recentlyChanged,
    required this.hasMoreChanged,
    required this.onFetchMoreChanged,
    required this.recentlyAdded,
    required this.hasMoreAdded,
    required this.onFetchMoreAdded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('library_snapshot').toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.translate('snapshot_desc'),
          style: AppTypography.sans(color: context.colors.textMuted),
        ),
        const SizedBox(height: 16),
        SnapshotList(
          title: l10n.translate('recently_changed'),
          entries: recentlyChanged,
          hasMore: hasMoreChanged,
          onFetchMore: onFetchMoreChanged,
        ),
        const SizedBox(height: 16),
        SnapshotList(
          title: l10n.translate('recently_added'),
          entries: recentlyAdded,
          hasMore: hasMoreAdded,
          onFetchMore: onFetchMoreAdded,
        ),
      ],
    );
  }
}
