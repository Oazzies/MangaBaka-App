import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';

class CollectionsBrowseHint extends StatelessWidget {
  final String text;

  const CollectionsBrowseHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.sans(color: context.colors.textMuted),
      ),
    ),
  );
}

class CollectionsPublisherRow extends StatelessWidget {
  final Publisher publisher;
  final VoidCallback onTap;

  const CollectionsPublisherRow({
    super.key,
    required this.publisher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    publisher.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CollectionsEditionRow extends StatelessWidget {
  final Edition edition;
  final bool selected;
  final VoidCallback? onTap;

  const CollectionsEditionRow({
    super.key,
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edition.name.toUpperCase(),
                  style: AppTypography.display(
                    color: selected
                        ? context.colors.accent
                        : context.colors.text,
                    fontSize: 14,
                  ),
                ),
                if (edition.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    edition.description,
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CollectionsDesktopTabLayer extends StatelessWidget {
  final bool active;
  final Widget child;

  const CollectionsDesktopTabLayer({
    super.key,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeFocus(
        excluding: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 260),
            curve: active
                ? const Interval(0.3, 1, curve: Curves.easeOut)
                : const Interval(0, 0.45, curve: Curves.easeIn),
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.02),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
