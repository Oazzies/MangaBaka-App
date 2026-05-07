import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/profile/widgets/mb_login_prompt.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';
import 'package:bakahyou/utils/transitions/app_transitions.dart';

class CurrentTab extends StatefulWidget {
  const CurrentTab({super.key});

  @override
  State<CurrentTab> createState() => _CurrentTabState();
}

class _CurrentTabState extends State<CurrentTab>
    with AutomaticKeepAliveClientMixin {
  final _libraryService = getIt<LibraryService>();
  final _authService = getIt<ProfileAuthService>();

  // Cached stream — do NOT recreate on every build.
  late final Stream<List<LibraryEntry>> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = _libraryService.watchEntriesFromDb();
    if (_authService.isLoggedIn) {
      _libraryService.performInitialSyncIfNeeded();
    }
  }

  Future<void> _handleLogin() async {
    try {
      await _authService.login();
      // The LibraryScreen detects auth changes and kicks off the import.
    } catch (e) {
      if (e is AuthCancelledException) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService().translate('login_failed'))),
      );
    }
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      AppTransitions.slideUp(SeriesDetailScreen(series: series)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // Auth & theme changes rebuild the outer shell only — not the StreamBuilder.
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), _authService, ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();

        if (!_authService.isLoggedIn) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: MBLoginPrompt(
              onLogin: _handleLogin,
              message: l10n.translate('login_prompt_library'),
            ),
          );
        }

        return _CurrentTabContent(
          stream: _stream,
          l10n: l10n,
          libraryService: _libraryService,
          onNavigate: _navigateToDetail,
        );
      },
    );
  }
}

/// Separated into its own StatelessWidget so that SettingsManager changes
/// (list-style toggles) only rebuild this subtree, not the StreamBuilder above.
class _CurrentTabContent extends StatelessWidget {
  final Stream<List<LibraryEntry>> stream;
  final LocalizationService l10n;
  final LibraryService libraryService;
  final void Function(Series) onNavigate;

  const _CurrentTabContent({
    required this.stream,
    required this.l10n,
    required this.libraryService,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LibraryEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        // Settings listenable only wraps the list rendering, not the stream.
        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final settings = SettingsManager();
            final isGrid = settings.separateListStyles
                ? settings.libraryListStyle.isGrid
                : settings.currentListStyle.isGrid;

            Widget content;

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              content = SeriesListSkeleton(
                key: const ValueKey('skeleton'),
                isGrid: isGrid,
              );
            } else {
              final entries = snapshot.data ?? [];
              final contentPreferences = settings.contentPreferences;
              
              final currentlyReading = entries
                  .where((e) {
                    final isReading = e.state.toLowerCase() == 'reading';
                    final matchesRating = contentPreferences.isEmpty ||
                        contentPreferences.contains(e.series.contentRating.toLowerCase());
                    return isReading && matchesRating;
                  })
                  .map((e) => e.series)
                  .toList()
                ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

              if (currentlyReading.isEmpty) {
                content = Center(
                  key: const ValueKey('empty'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          color: AppConstants.textMutedColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('no_entries_category'),
                        style:
                            TextStyle(color: AppConstants.textMutedColor),
                      ),
                    ],
                  ),
                );
              } else {
                content = RefreshIndicator(
                  key: const ValueKey('list'),
                  onRefresh: () => libraryService.syncLibrary(),
                  color: AppConstants.accentColor,
                  backgroundColor: AppConstants.secondaryBackground,
                  child: isGrid
                      ? GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: currentlyReading.length,
                          itemBuilder: (context, index) {
                            final series = currentlyReading[index];
                            return InkWell(
                              onTap: () => onNavigate(series),
                              child: EntryListItem(series: series),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          itemCount: currentlyReading.length,
                          itemBuilder: (context, index) {
                            final series = currentlyReading[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () => onNavigate(series),
                                borderRadius: BorderRadius.circular(8),
                                child: EntryListItem(series: series),
                              ),
                            );
                          },
                        ),
                );
              }
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: content,
            );
          },
        );
      },
    );
  }
}
