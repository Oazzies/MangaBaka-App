import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/status_icons.dart';
import 'package:mangabaka_app/core/widgets/beside_or_below.dart';
import 'package:mangabaka_app/features/library/import/import_export_screen.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/core/utils/number_utils.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_filter_panel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_sign_in_prompt.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/utils/browse_helpers.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/controllers/library_session.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/models/library_sync_status.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/library/services/state_normalizer.dart';
import 'package:mangabaka_app/features/library/widgets/library_grid_list.dart';
import 'package:mangabaka_app/features/library/widgets/library_search_bar.dart';
import 'package:mangabaka_app/features/library/widgets/library_status_banners.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart' as api;
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/series_list_skeleton.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_library_rail_part.dart';

/// The library on desktop.
///
/// The phone's swipeable status tabs become a status list in the left panel —
/// with an "All" view the tabs never had — and the filter sheet becomes the
/// always-visible filters beneath it. Search, sort, layout and sync sit in a
/// toolbar over the grid.
///
/// Account wiring is the shared [LibrarySession]; filtering is the shared
/// [LibraryFilterHelper].
class DesktopLibraryScreen extends StatefulWidget {
  static final GlobalKey<DesktopLibraryScreenState> stateKey =
      GlobalKey<DesktopLibraryScreenState>();

  const DesktopLibraryScreen({super.key});

  @override
  State<DesktopLibraryScreen> createState() => DesktopLibraryScreenState();
}

class DesktopLibraryScreenState extends State<DesktopLibraryScreen>
    implements DesktopRefreshable {
  static final _logger = LoggingService.logger;

  /// The status key for the unfiltered "everything" view.
  static const String allKey = 'all';

  late final LibraryService _libraryService;
  late final LibrarySession _session;
  final FocusNode _searchFocus = FocusNode();
  final Map<String, ScrollController> _scrollControllers = {};

  List<LibraryEntry>? _entries;
  String _status = LibraryScreenConstants.tabs.first.key;
  String _query = '';
  SearchFilters _filters = SearchFilters();

  void focusSearch() => _searchFocus.requestFocus();

  @override
  Future<void> refresh() => _session.refresh();

  @override
  void initState() {
    super.initState();
    _libraryService = getIt<LibraryService>();
    _session = LibrarySession(onEntries: _onEntries);
    _session.addListener(_onSession);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _session.dispose();
    for (final c in _scrollControllers.values) {
      c.dispose();
    }
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    setState(() {
      if (!_session.isLoggedIn) _entries = null;
    });
  }

  void _onEntries(List<LibraryEntry> entries) {
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  ScrollController _scrollFor(String key) =>
      _scrollControllers.putIfAbsent(key, ScrollController.new);

  Future<void> _login() async {
    final errorKey = await _session.login();
    if (errorKey == null || !mounted) return;
    AppSnackBar.show(
      context,
      LocalizationService().translate(errorKey),
      isError: true,
    );
  }

  void _openDetail(api.Series series) {
    Navigator.of(
      context,
    ).push(AppTransitions.slideUp(SeriesDetailScreen(series: series)));
  }

  void _onResultSelected(AutocompleteSeriesResult result) {
    _logger.info('Library autocomplete result selected: ${result.title}');
    _openDetail(BrowseHelpers.convertAutocompleteToSeries(result));
  }

  // ─── Filtering ───────────────────────────────────────────────────────────

  LibraryFilterHelper _helper(List<LibraryEntry> entries) =>
      LibraryFilterHelper(
        allEntries: entries,
        query: _query,
        filters: _filters,
        contentPreferences: SettingsManager().contentPreferences,
      );

  /// Counts per status, over the same filtered set the grid shows.
  Map<String, int> _counts(LibraryFilterHelper helper) {
    final counts = <String, int>{};
    for (final entry in helper.getFilteredAndSorted()) {
      var state = StateNormalizer.normalize(entry.state);
      if (!LibraryScreenConstants.knownStates.contains(state)) {
        state = 'reading';
      }
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return counts;
  }

  void _setQuery(String q) {
    setState(() => _query = q);
    _followMatches();
  }

  void _setFilters(SearchFilters f) {
    setState(() => _filters = f);
    _followMatches();
  }

  /// While searching, an empty status with matches elsewhere switches to
  /// "All" — the status the user was on is rarely what a search meant.
  void _followMatches() {
    final entries = _entries;
    if (entries == null || _status == allKey) return;
    if (_query.isEmpty && _filters.isEmpty) return;
    final helper = _helper(entries);
    if (helper.getByTab(_status).isNotEmpty) return;
    if (helper.getFilteredAndSorted().isEmpty) return;
    setState(() => _status = allKey);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (!_session.isLoggedIn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopPageHeader(title: l10n.translate('library')),
              Expanded(
                child: DesktopSignInPrompt(
                  title: l10n.translate('library'),
                  message: l10n.translate('login_prompt_library'),
                  onLogin: _login,
                  icon: Icons.bookmark_outline_rounded,
                ),
              ),
            ],
          );
        }

        final entries = _entries;
        final helper = entries == null ? null : _helper(entries);
        final counts = helper == null ? const <String, int>{} : _counts(helper);
        final total = helper?.getFilteredAndSorted().length ?? 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopSidePanel(
              child: DesktopFilterPanel(
                filters: _filters,
                onChanged: _setFilters,
                tagsByName: true,
                header: _StatusList(
                  selected: _status,
                  counts: counts,
                  total: total,
                  onSelected: (key) => setState(() => _status = key),
                ),
              ),
            ),
            Expanded(child: _main(l10n, helper, total)),
          ],
        );
      },
    );
  }

  Widget _main(
    LocalizationService l10n,
    LibraryFilterHelper? helper,
    int total,
  ) {
    final statusLabel = _status == allKey
        ? l10n.translate('all')
        : l10n.translate(_status);

    return ValueListenableBuilder<LibrarySyncStatus>(
      valueListenable: _libraryService.syncStatus,
      builder: (context, status, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopPageHeader(
              title: l10n.translate('library'),
              subtitle: helper == null
                  ? null
                  : '$statusLabel · ${l10n.translate('series_count').replaceAll('{count}', NumberUtils.formatCount(helper.getByTabOrAll(_status).length))}',
              actions: [
                DesktopPillButton(
                  label: l10n.translate('import_export_title'),
                  icon: Icons.import_export_rounded,
                  onPressed: () => ImportExportScreen.open(context),
                ),
                DesktopPillButton(
                  label: l10n.translate(
                    status.isSyncing ? 'syncing' : 'sync_now',
                  ),
                  icon: Icons.sync_rounded,
                  onPressed: status.isSyncing ? null : _session.refresh,
                ),
              ],
            ),
            LibraryStatusBanners(
              status: status,
              isIncomplete: _session.isIncomplete,
              onRetrySync: _session.refresh,
              onDismissError: () => _libraryService.syncStatus.value =
                  _libraryService.syncStatus.value.copyWith(clearError: true),
              onImportFullLibrary: _libraryService.importFullLibrary,
            ),
            _DesktopLibraryToolbar(
              searchFocus: _searchFocus,
              session: _session,
              filters: _filters,
              onQueryChanged: _setQuery,
              onResultSelected: _onResultSelected,
              onFiltersChanged: _setFilters,
            ),
            Expanded(
              child: _DesktopLibraryGrid(
                helper: helper,
                status: _status,
                scrollController: _scrollFor(_status),
                onRefresh: _session.refresh,
                onItemTap: _openDetail,
              ),
            ),
          ],
        );
      },
    );
  }
}
