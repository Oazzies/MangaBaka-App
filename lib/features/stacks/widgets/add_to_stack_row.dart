import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';

/// A single stack row inside [showAddToStackSheet].
class AddToStackRow extends StatelessWidget {
  final MySeriesStack stack;
  final bool busy;
  final LocalizationService l10n;
  final VoidCallback onTap;

  const AddToStackRow({
    super.key,
    required this.stack,
    required this.busy,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = stack.contains || stack.canAdd;
    final subtitle = [
      l10n.translate(stack.visibility.labelKey),
      stackCount('entries', stack.entryCount, l10n),
      if (stack.contains)
        l10n.translate('stacks_at_rank').replaceAll('{n}', '${stack.rank}'),
      if (!stack.contains && !stack.canAdd)
        l10n.translate('stacks_cannot_add'),
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      enabled: enabled && !busy,
      onTap: onTap,
      leading: Icon(
        Icons.layers_rounded,
        color: stack.contains ? c.accent : c.textMuted,
      ),
      title: Text(
        stack.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.sans(
          color: c.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.sans(color: c.textMuted, fontSize: 12.5),
      ),
      trailing: busy
          ? const SizedBox(width: 22, height: 22, child: MbSpinner())
          : Icon(
              stack.contains
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: stack.contains ? c.accent : c.textMuted,
            ),
    );
  }
}
