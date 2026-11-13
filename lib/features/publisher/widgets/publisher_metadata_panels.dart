import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/collections/models/edition.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_panel.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OpenPublisherCallback =
    void Function(BuildContext context, {required String id, Publisher? publisher, String? name});

class PublisherEditionTile extends StatelessWidget {
  final Edition edition;
  final bool selected;
  final VoidCallback onTap;

  const PublisherEditionTile({
    super.key,
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          edition.name.toUpperCase(),
          style: AppTypography.display(
            color: selected ? colors.accent : colors.text,
            fontSize: 14,
          ),
        ),
        if (edition.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            edition.description,
            style: AppTypography.sans(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DesktopLayout.isActive(context)
          ? DesktopHoverSurface(
              onTap: onTap,
              idleColor: colors.surface,
              borderRadius: BorderRadius.circular(DesktopTokens.panelRadius),
              padding: const EdgeInsets.all(18),
              child: SizedBox(width: double.infinity, child: content),
            )
          : Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, child: content),
                ),
              ),
            ),
    );
  }
}

class PublisherFamilyPanel extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final OpenPublisherCallback onOpenPublisher;

  const PublisherFamilyPanel({
    super.key,
    required this.publisher,
    required this.l10n,
    required this.onOpenPublisher,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill(Publisher p) => MbPill(
      label: p.name,
      icon: Icons.business_rounded,
      onTap: p.id.isEmpty
          ? null
          : () => onOpenPublisher(context, id: p.id, publisher: p),
    );

    return PublisherPanel(
      label: publisher.parent != null && publisher.imprints.isEmpty
          ? l10n.translate('publisher_parent')
          : l10n.translate('publisher_imprints_title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (publisher.parent != null) ...[
            PublisherSubLabel(l10n.translate('publisher_parent')),
            const SizedBox(height: 8),
            Wrap(children: [pill(publisher.parent!)]),
            if (publisher.imprints.isNotEmpty) const SizedBox(height: 14),
          ],
          if (publisher.imprints.isNotEmpty) ...[
            if (publisher.parent != null) ...[
              PublisherSubLabel(l10n.translate('publisher_imprints_title')),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final i in publisher.imprints) pill(i)],
            ),
          ],
        ],
      ),
    );
  }
}

class PublisherAliasesPanel extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const PublisherAliasesPanel({
    super.key,
    required this.publisher,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final aliases = [...publisher.aliases]
      ..sort((a, b) => _rank(a).compareTo(_rank(b)));
    return PublisherPanel(
      label: l10n.translate('publisher_aliases'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in aliases.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (a.language.isNotEmpty && a.language != 'unknown')
                    SizedBox(
                      width: 32,
                      child: Text(
                        a.language.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      a.title,
                      style: AppTypography.sans(
                        color: context.colors.text,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _rank(PublisherAlias a) => switch (a.type) {
    'native' => 0,
    'official' => 1,
    _ => 2,
  };
}

class PublisherLinksPanel extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;

  const PublisherLinksPanel({
    super.key,
    required this.publisher,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return PublisherPanel(
      label: l10n.translate('publisher_links'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final link in publisher.links)
            if (Uri.tryParse(link.link) case final uri? when uri.hasScheme)
              MbPill(
                label: link.type.isEmpty
                    ? uri.host
                    : '${capitalizePublisherKey(link.type)} · ${uri.host}',
                icon: Icons.link_rounded,
                onTap: () =>
                    launchUrl(uri, mode: LaunchMode.externalApplication),
              ),
        ],
      ),
    );
  }
}

class PublisherSimilarPanel extends StatelessWidget {
  final List<SimilarPublisher> items;
  final LocalizationService l10n;
  final OpenPublisherCallback onOpenPublisher;

  const PublisherSimilarPanel({
    super.key,
    required this.items,
    required this.l10n,
    required this.onOpenPublisher,
  });

  @override
  Widget build(BuildContext context) {
    return PublisherPanel(
      label: l10n.translate('publisher_similar'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in items)
            MbPill(
              label: s.name,
              icon: Icons.business_rounded,
              onTap: () => onOpenPublisher(context, id: s.id, name: s.name),
            ),
        ],
      ),
    );
  }
}
