import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/my_stacks_screen.dart';
import 'package:mangabaka_app/features/stacks/services/stack_service.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_grid.dart';

/// The Profile's stacks: a rail of the reader's own, like Home's. Until there
/// are some to show (none yet, or the request failed) it is a single row card
/// that opens My Stacks, where they can make their first.
class MyStacksEntryCard extends StatefulWidget {
  /// Replaces the service lookup, for tests.
  final Future<List<StackSummary>> Function()? loader;

  const MyStacksEntryCard({super.key, this.loader});

  @override
  State<MyStacksEntryCard> createState() => _MyStacksEntryCardState();
}

class _MyStacksEntryCardState extends State<MyStacksEntryCard> {
  static const int _count = 12;

  List<StackSummary> _stacks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loader = widget.loader;
      final List<StackSummary> found;
      if (loader != null) {
        found = await loader();
      } else if (getIt.isRegistered<StackService>()) {
        found = (await getIt<StackService>().mine(limit: _count)).items;
      } else {
        return;
      }
      if (mounted) setState(() => _stacks = found);
    } catch (e) {
      LoggingService.logger.warning('Profile stacks rail failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    if (_stacks.isEmpty) return _LinkCard(l10n: l10n);
    return StacksRail(
      title: l10n.translate('stacks_my'),
      stacks: _stacks,
      showVisibility: true,
      gutter: 0,
      onViewAll: () => MyStacksScreen.open(context),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final LocalizationService l10n;

  const _LinkCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Built like the Profile's other blocks: a surface card with a caps
    // heading, a muted line under it, and one accent action on the end.
    return MbTappable(
      pressedScale: 0.98,
      onTap: () => MyStacksScreen.open(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers_rounded, size: 18, color: c.textMuted),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.translate('stacks_my').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            color: c.text,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('stacks_my_subtitle'),
                    style: AppTypography.sans(
                      color: c.textMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: c.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
