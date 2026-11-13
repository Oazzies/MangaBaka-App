import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/stacks/models/stack_detail.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';

/// Asks before deleting a stack. Returns whether to go ahead.
Future<bool> confirmStackDelete(BuildContext context, String title) async {
  final l10n = LocalizationService();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(l10n.translate('stacks_delete_title')),
      content: Text(
        l10n.translate('stacks_delete_body').replaceAll('{title}', title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.translate('stacks_delete'),
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

class StackDetailHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const StackDetailHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.sans(
                color: c.text,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StackSpoilerGate extends StatelessWidget {
  final VoidCallback onReveal;

  const StackSpoilerGate({super.key, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(Icons.visibility_off_rounded, color: c.warning, size: 32),
          const SizedBox(height: 10),
          Text(
            l10n.translate('stacks_spoiler_title'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.translate('stacks_spoiler_body'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: c.textMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_rounded),
            label: Text(l10n.translate('stacks_spoiler_reveal')),
          ),
        ],
      ),
    );
  }
}

/// An entry whose series was merged away or removed: it keeps its rank.
class StackPlaceholderTile extends StatelessWidget {
  final StackEntry entry;
  final bool compact;

  const StackPlaceholderTile({
    super.key,
    required this.entry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final text = l10n.translate(
      entry.issue == StackEntryIssue.deleted
          ? 'stacks_entry_deleted'
          : 'stacks_entry_merged',
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${entry.rank}',
                  style: AppTypography.display(color: c.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.sans(color: c.textMuted, fontSize: 12),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  '#${entry.rank}',
                  style: AppTypography.display(color: c.textMuted),
                ),
                const SizedBox(width: 14),
                Icon(Icons.link_off_rounded, color: c.textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.sans(color: c.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}

class StackEmptyEntries extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onEdit;

  const StackEmptyEntries({
    super.key,
    required this.isOwner,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.layers_clear_rounded, size: 40, color: c.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.translate('stacks_empty_entries'),
            textAlign: TextAlign.center,
            style: AppTypography.sans(color: c.textMuted, fontSize: 14),
          ),
          if (isOwner) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translate('stacks_add_series')),
            ),
          ],
        ],
      ),
    );
  }
}

class StackErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const StackErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_rounded, size: 40, color: c.textMuted),
            const SizedBox(height: 12),
            Text(
              stackErrorMessage(error, l10n),
              textAlign: TextAlign.center,
              style: AppTypography.sans(color: c.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
