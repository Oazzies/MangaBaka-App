import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/widgets/mini_badge.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class IdChip extends StatelessWidget {
  final String id;
  const IdChip({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: LocalizationService().translate('click_to_copy_id'),
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService().translate('id_copied').replaceAll('{id}', id)),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                width: 250,
              ),
            );
          }
        },
        child: MiniBadge(
          text: 'ID: $id',
          icon: Icons.fingerprint_outlined,
        ),
      ),
    );
  }
}
