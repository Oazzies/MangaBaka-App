import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/shortcut_button.dart';

class ShortcutSection extends StatelessWidget {
  final String header;
  final VoidCallback onMostPopular;
  final VoidCallback onRandom;

  const ShortcutSection({
    required this.header,
    required this.onMostPopular,
    required this.onRandom,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 3.0),
                  child: ShortcutButton(
                    icon: Icons.star_outline,
                    label: 'Most Popular',
                    onPressed: onMostPopular,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: ShortcutButton(
                    icon: Icons.casino_outlined,
                    label: 'Random',
                    onPressed: onRandom,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
