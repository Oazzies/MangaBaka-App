import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/profile/widgets/snapshot/snapshot_list_item.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class SnapshotList extends StatefulWidget {
  final String title;
  final List<LibraryEntry> entries;
  final VoidCallback onFetchMore;
  final bool hasMore;

  const SnapshotList({
    super.key,
    required this.title,
    required this.entries,
    required this.onFetchMore,
    required this.hasMore,
  });

  @override
  State<SnapshotList> createState() => _SnapshotListState();
}

class _SnapshotListState extends State<SnapshotList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onFetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title.toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          // Cover width (120) at the standard 2:3 ratio (180) plus the
          // caption row below it (4 spacing + 16 text).
          height: SnapshotListItem.width * 1.5 + 20,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.hasMore
                ? widget.entries.length + 1
                : widget.entries.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index >= widget.entries.length) {
                return Center(child: MbSpinner(color: context.colors.accent));
              }
              final entry = widget.entries[index];
              return SnapshotListItem(series: entry.series);
            },
          ),
        ),
      ],
    );
  }
}
