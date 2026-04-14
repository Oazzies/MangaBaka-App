import 'package:flutter/material.dart';
import '../chip.dart';

class VolumeChip extends StatelessWidget {
  final String volume;
  const VolumeChip({required this.volume, super.key});

  @override
  Widget build(BuildContext context) {
    if (volume.isEmpty || volume == 'null') return SizedBox.shrink();
    return ChipBase(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shelves, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text('$volume Vol.'),
        ],
      ),
    );
  }
}