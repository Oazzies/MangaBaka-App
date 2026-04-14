import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DescriptionSection extends StatefulWidget {
  final String description;
  const DescriptionSection({required this.description});

  @override
  State<DescriptionSection> createState() => DescriptionSectionState();
}

class DescriptionSectionState extends State<DescriptionSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong =
        widget.description
                .trim()
                .split('\n')
                .expand((l) => l.split(' '))
                .length >
            40 ||
        widget.description.length > 400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          maxLines: expanded ? null : 5,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (isLong || widget.description.isNotEmpty)
          SizedBox(
            height: 36,
            child: Stack(
              children: [
                if (isLong)
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () => setState(() => expanded = !expanded),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy description',
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: widget.description),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
