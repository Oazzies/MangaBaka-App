import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/features/series/widgets/mini_badge.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';

class IdChip extends StatelessWidget {
  final String id;
  const IdChip({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetUtils.tooltip(
      message: LocalizationService().translate('copy_id'),
      child: MiniBadge(
        text: 'ID: $id',
        icon: Icons.fingerprint_outlined,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: id));
          if (context.mounted) {
            AppSnackBar.show(
              context,
              LocalizationService()
                  .translate('id_copied')
                  .replaceAll('{id}', id),
              duration: const Duration(seconds: 1),
            );
          }
        },
      ),
    );
  }
}
