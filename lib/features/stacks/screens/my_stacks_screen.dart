import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_editor_screen.dart';
import 'package:mangabaka_app/features/stacks/screens/stacks_list_screen.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_auth_gate.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

enum _MyTab { mine, saved, followed }

/// The reader's stacks: the ones they made (drafts included), and the ones
/// they saved or follow.
class MyStacksScreen extends StatefulWidget {
  const MyStacksScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(AppTransitions.slideRight(const MyStacksScreen()));

  @override
  State<MyStacksScreen> createState() => _MyStacksScreenState();
}

class _MyStacksScreenState extends State<MyStacksScreen> {
  late final ProfileAuthService _auth = getIt<ProfileAuthService>();
  final LocalizationService _l10n = LocalizationService();
  _MyTab _tab = _MyTab.mine;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuth);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    if (mounted) setState(() {});
  }

  StacksListSource get _source => switch (_tab) {
    _MyTab.mine => const StacksListSource.mine(),
    _MyTab.saved => const StacksListSource.saved(),
    _MyTab.followed => const StacksListSource.followed(),
  };

  String _label(_MyTab t) => _l10n.translate(switch (t) {
    _MyTab.mine => 'stacks_tab_mine',
    _MyTab.saved => 'stacks_tab_saved',
    _MyTab.followed => 'stacks_tab_followed',
  });

  Future<void> _create() async {
    if (!await ensureStackAccess(context)) return;
    if (mounted) await StackEditorScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isActive(context);
    final access = stackAccess(_auth);

    final Widget body;
    if (access != StackAccess.ready) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.horizontalPadding),
            child: StackAccessPrompt(
              access: access,
              onReady: () => setState(() {}),
            ),
          ),
        ),
      );
    } else {
      body = StacksPagedView(
        key: ValueKey(_tab),
        source: _source,
        leading: [
          if (!desktop)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.horizontalPadding,
                  4,
                  AppConstants.horizontalPadding,
                  4,
                ),
                child: Row(
                  children: [
                    for (final t in _MyTab.values) ...[
                      if (t.index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: MbPill(
                          label: _label(t),
                          selected: _tab == t,
                          expand: true,
                          onTap: () => setState(() => _tab = t),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    }

    if (desktop) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              leading: Navigator.of(context).canPop()
                  ? DesktopIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: _l10n.translate('stacks_my'),
              subtitle: _l10n.translate('stacks'),
              actions: [
                if (access == StackAccess.ready) ...[
                  DesktopSegmented<_MyTab>(
                    value: _tab,
                    segments: [
                      for (final t in _MyTab.values) (t, _label(t), null),
                    ],
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  DesktopPillButton(
                    label: _l10n.translate('stacks_create'),
                    icon: Icons.add_rounded,
                    primary: true,
                    onPressed: _create,
                  ),
                ],
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: _l10n.translate('stacks_my')),
      floatingActionButton: access == StackAccess.ready
          ? FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: context.colors.accent,
              foregroundColor: context.colors.onAccent,
              icon: const Icon(Icons.add_rounded),
              label: Text(_l10n.translate('stacks_create_short')),
            )
          : null,
      body: body,
    );
  }
}
