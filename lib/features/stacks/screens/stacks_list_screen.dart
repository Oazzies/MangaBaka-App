import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/stacks/models/stacks_list_source.dart';
import 'package:mangabaka_app/features/stacks/widgets/stacks_paged_view.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

export 'package:mangabaka_app/features/stacks/models/stacks_list_source.dart';
export 'package:mangabaka_app/features/stacks/widgets/stacks_paged_view.dart';

/// Pages through one [StacksListSource] as a full screen.
class StacksListScreen extends StatelessWidget {
  final StacksListSource source;

  const StacksListScreen({super.key, required this.source});

  static Future<void> open(BuildContext context, StacksListSource source) =>
      Navigator.of(
        context,
      ).push(AppTransitions.slideRight(StacksListScreen(source: source)));

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final title = source.title(l10n);
    if (DesktopLayout.isActive(context)) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: DesktopIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: title,
              subtitle: source.subtitle(l10n) ?? l10n.translate('stacks'),
            ),
            Expanded(child: StacksPagedView(source: source)),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: title),
      body: StacksPagedView(source: source),
    );
  }
}
