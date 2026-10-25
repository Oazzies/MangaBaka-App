import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/widgets/share_menu.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/publisher/utils/format_count.dart';
import 'package:mangabaka_app/features/stacks/controllers/stack_status_controller.dart';
import 'package:mangabaka_app/features/stacks/models/stack_status.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/services/stack_exceptions.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';

StackStatus _fallbackStatus(StackSummary stack) => StackStatus(
  id: stack.id,
  voteCount: stack.voteCount,
  saveCount: stack.saveCount,
);

Future<void> _toggleReaction(
  BuildContext context,
  StackSummary stack,
  StackReaction reaction,
) async {
  if (!await ensureStackAccess(context)) return;
  final controller = getIt<StackStatusController>();
  try {
    await controller.toggle(
      stack.id,
      reaction,
      fallback: _fallbackStatus(stack),
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackBar.show(
        context,
        stackErrorMessage(e, LocalizationService()),
        isError: true,
      );
    }
  }
}

void _shareStack(BuildContext context, StackSummary stack) {
  final box = context.findRenderObject() as RenderBox?;
  final l10n = LocalizationService();
  showShareChoice(
    context,
    text: '${stack.title}\n${stack.canonicalUrl}',
    shareLabel: l10n.translate('stacks_share'),
    copyLabel: l10n.translate('copy_link'),
    copiedMessage: l10n.translate('stacks_link_copied'),
    anchor: box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null,
  );
}

/// Upvote and follow a stack, and open its comments on the website.
///
/// Save and share live in the top bar ([StackBarActions]). State comes from
/// [StackStatusController], so the counts agree with every other place the
/// stack is shown. Signed-out readers see the listing's counts and are asked
/// to sign in when they press one.
class StackActionBar extends StatelessWidget {
  final StackSummary stack;
  final bool commentsEnabled;

  const StackActionBar({
    super.key,
    required this.stack,
    this.commentsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = getIt<StackStatusController>();
    controller.request([stack.id]);
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.of(stack.id) ?? _fallbackStatus(stack);
        final busy = controller.isBusy(stack.id);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StackActionButton(
              icon: status.hasVoted
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              label: formatCount(status.voteCount),
              tooltip: l10n.translate(
                status.hasVoted ? 'stacks_action_unvote' : 'stacks_action_vote',
              ),
              active: status.hasVoted,
              onTap: busy
                  ? null
                  : () => _toggleReaction(context, stack, StackReaction.vote),
            ),
            StackActionButton(
              icon: status.hasFollowed
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              label: l10n.translate(
                status.hasFollowed
                    ? 'stacks_action_following'
                    : 'stacks_action_follow',
              ),
              tooltip: l10n.translate('stacks_action_follow_hint'),
              active: status.hasFollowed,
              onTap: busy
                  ? null
                  : () => _toggleReaction(context, stack, StackReaction.follow),
            ),
            // Comments open the website for now; the API has no comments
            // endpoint yet. Re-enable when it does and build them in-app.
            // if (commentsEnabled)
            //   StackActionButton(
            //     icon: Icons.chat_bubble_outline_rounded,
            //     label: l10n.translate('stacks_action_comments_short'),
            //     tooltip: l10n.translate('stacks_action_comments'),
            //     onTap: () => launchUrl(
            //       Uri.parse('${stack.canonicalUrl}#comments'),
            //       mode: LaunchMode.externalApplication,
            //     ),
            //   ),
          ],
        );
      },
    );
  }
}

/// Save and share, as icon buttons for the top bar ([desktop] picks the
/// desktop header's style). Long-pressing share copies the link.
List<Widget> stackBarActions(
  BuildContext context,
  StackSummary stack, {
  required bool desktop,
}) {
  final l10n = LocalizationService();
  final controller = getIt<StackStatusController>();
  controller.request([stack.id]);
  final c = context.colors;

  Widget button({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? color,
  }) {
    if (desktop) {
      return DesktopIconButton(
        icon: icon,
        tooltip: tooltip,
        color: color,
        onPressed: onTap,
      );
    }
    return GestureDetector(
      onLongPress: onLongPress,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: color ?? c.text),
        onPressed: onTap,
      ),
    );
  }

  return [
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final saved =
            (controller.of(stack.id) ?? _fallbackStatus(stack)).hasSaved;
        return button(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          tooltip: l10n.translate(
            saved ? 'stacks_action_saved' : 'stacks_action_save_hint',
          ),
          color: saved ? c.accent : null,
          onTap: controller.isBusy(stack.id)
              ? () {}
              : () => _toggleReaction(context, stack, StackReaction.save),
        );
      },
    ),
    Builder(
      builder: (buttonContext) => button(
        icon: Icons.share_outlined,
        tooltip: l10n.translate('stacks_action_share'),
        onTap: () => _shareStack(buttonContext, stack),
      ),
    ),
  ];
}

/// A rounded action button: an icon with an optional label, filled with the
/// accent while [active], and lighter under the pointer.
class StackActionButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const StackActionButton({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    this.active = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<StackActionButton> createState() => _StackActionButtonState();
}

class _StackActionButtonState extends State<StackActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = widget.active;
    final enabled = widget.onTap != null;
    final hover = _hovered && enabled;
    final fg = active ? c.onAccent : (hover ? c.accent : c.text);
    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MbTappable(
        pressedScale: 0.94,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 40,
          padding: EdgeInsets.symmetric(
            horizontal: widget.label == null ? 11 : 14,
          ),
          decoration: BoxDecoration(
            color: active
                ? (hover ? Color.lerp(c.accent, c.text, 0.12) : c.accent)
                : (hover ? c.border : c.surfaceRaised),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active || hover ? c.accent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: fg),
              if (widget.label != null) ...[
                const SizedBox(width: 7),
                Text(
                  widget.label!,
                  style: AppTypography.sans(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final semantic = Semantics(
      button: true,
      toggled: active,
      label: widget.tooltip ?? widget.label,
      child: button,
    );
    return widget.tooltip == null
        ? semantic
        : Tooltip(message: widget.tooltip!, child: semantic);
  }
}
