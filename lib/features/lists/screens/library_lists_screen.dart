import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/lists/controllers/library_list_detail_controller.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/screens/library_list_screen.dart';
import 'package:mangabaka_app/features/lists/screens/library_lists_wide_layout.dart';
import 'package:mangabaka_app/features/lists/services/library_lists_service.dart';
import 'package:mangabaka_app/features/lists/widgets/library_list_flows.dart';
import 'package:mangabaka_app/features/lists/widgets/library_lists_pane.dart';
import 'package:mangabaka_app/features/lists/widgets/lists_sign_in_prompt.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// Every list. Phones push a list on top; from [wideBreakpoint] the list opens beside them.
class LibraryListsScreen extends StatefulWidget {
  static const double wideBreakpoint = 720;

  final LibraryListsService service;
  final LibraryService library;
  final ProfileAuthService auth;
  final SeriesSearchService? search;

  const LibraryListsScreen({
    super.key,
    required this.service,
    required this.library,
    required this.auth,
    this.search,
  });

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    AppTransitions.slideRight(
      LibraryListsScreen(
        service: getIt<LibraryListsService>(),
        library: getIt<LibraryService>(),
        auth: getIt<ProfileAuthService>(),
        search: getIt<SeriesSearchService>(),
      ),
    ),
  );

  @override
  State<LibraryListsScreen> createState() => _LibraryListsScreenState();
}

class _LibraryListsScreenState extends State<LibraryListsScreen> {
  late final LibraryListsController _lists = LibraryListsController(
    service: widget.service,
    library: widget.library,
  );
  late final LibraryListFlows _flows = LibraryListFlows(
    _lists,
    search: widget.search,
  );
  late final SeriesListDeps _deps = SeriesListDeps.fromLocator();

  LibraryListDetailController? _detail;

  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _lists.addListener(_onLists);
    widget.auth.addListener(_onAuth);
    _signedIn = widget.auth.isLoggedIn;
    if (_signedIn) _lists.refresh();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuth);
    _lists.removeListener(_onLists);
    _detail?.dispose();
    _lists.dispose();
    super.dispose();
  }

  void _onAuth() {
    if (widget.auth.isLoggedIn == _signedIn || !mounted) return;
    setState(() => _signedIn = widget.auth.isLoggedIn);
    if (_signedIn) _lists.refresh();
  }

  /// The wide layout opens the first list rather than leave its right pane blank.
  void _ensureActive() {
    if (_detail != null || !_lists.isLoaded) return;
    final first = _lists.visible.firstOrNull;
    if (first == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _detail == null) _activate(first);
    });
  }

  /// A deleted active list leaves the wide layout's right pane empty rather than stale.
  void _onLists() {
    final detail = _detail;
    if (detail == null || !_lists.isLoaded) return;
    if (_lists.byId(detail.listId) != null) return;
    setState(() {
      _detail = null;
      detail.dispose();
    });
  }

  void _activate(LibraryList list) {
    if (_detail?.listId == list.id) return;
    final previous = _detail;
    setState(() {
      _detail = LibraryListDetailController(lists: _lists, listId: list.id);
    });
    previous?.dispose();
  }

  void _open(LibraryList list, {required bool wide}) {
    if (wide) {
      _activate(list);
      return;
    }
    LibraryListScreen.open(
      context,
      lists: _lists,
      flows: _flows,
      listId: list.id,
      deps: _deps,
    );
  }

  Future<void> _create({required bool wide}) async {
    final created = await _flows.create(context);
    if (created != null && wide && mounted) _activate(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return DerivedLayoutBuilder<bool>(
      derive: (c) => c.maxWidth >= LibraryListsScreen.wideBreakpoint,
      builder: (context, wide) => ListenableBuilder(
        listenable: Listenable.merge([_lists, ?_detail]),
        builder: (context, _) => PopScope(
          // Back clears a selection in either pane before it leaves.
          canPop: !_lists.isSelecting && !(_detail?.isSelecting ?? false),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _lists.clearSelection();
            _detail?.clearSelection();
          },
          child: Scaffold(
            backgroundColor: context.colors.background,
            appBar: mbScreenAppBar(
              title: l10n.translate('lists'),
              actions: [
                if (wide && _signedIn)
                  IconButton(
                    tooltip: l10n.translate('lists_new'),
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _create(wide: true),
                  ),
                const SizedBox(width: 4),
              ],
            ),
            // The selection bar takes the bottom edge while selecting.
            floatingActionButton: wide || !_signedIn || _lists.isSelecting
                ? null
                : FloatingActionButton.extended(
                    key: const ValueKey('lists_new_fab'),
                    onPressed: () => _create(wide: false),
                    backgroundColor: context.colors.accent,
                    foregroundColor: context.colors.onAccent,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.translate('lists_new')),
                  ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: !_signedIn
                  ? ListsSignInPrompt(auth: widget.auth)
                  : wide
                  ? _wide()
                  : LibraryListsPane(
                      lists: _lists,
                      flows: _flows,
                      onOpen: (l) => _open(l, wide: false),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wide() {
    _ensureActive();
    return LibraryListsWideLayout(
      lists: _lists,
      flows: _flows,
      detail: _detail,
      deps: _deps,
      onOpen: (l) => _open(l, wide: true),
    );
  }
}
