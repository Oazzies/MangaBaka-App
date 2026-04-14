import 'package:flutter/material.dart';

class ExpandableChipWrap extends StatefulWidget {
  final String label;
  final List<String> items;
  final Color? color;

  const ExpandableChipWrap({
    required this.label,
    required this.items,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  State<ExpandableChipWrap> createState() => _ExpandableChipWrapState();
}

class _ExpandableChipWrapState extends State<ExpandableChipWrap> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final chipsPerRow = (MediaQuery.of(context).size.width / 100).floor();
    final maxChips = chipsPerRow * 3;
    final showExpand = widget.items.length > maxChips;

    final chips = widget.items
        .map((e) => Chip(label: Text(e), backgroundColor: widget.color))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: expanded || !showExpand ? chips : chips.take(maxChips).toList(),
        ),
        if (showExpand)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Show less' : 'Show all'),
              onPressed: () => setState(() => expanded = !expanded),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}