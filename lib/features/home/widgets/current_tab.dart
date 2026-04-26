import 'package:flutter/material.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/profile/widgets/mb_login_prompt.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/exceptions/app_exceptions.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class CurrentTab extends StatefulWidget {
  const CurrentTab({super.key});

  @override
  State<CurrentTab> createState() => _CurrentTabState();
}

class _CurrentTabState extends State<CurrentTab> {
  final _libraryService = getIt<LibraryService>();
  final _authService = getIt<ProfileAuthService>();

  @override
  void initState() {
    super.initState();
    if (_authService.isLoggedIn) {
      _libraryService.performInitialSyncIfNeeded();
    }
  }

  Future<void> _handleLogin() async {
    try {
      await _authService.login();
      if (_authService.isLoggedIn) {
        await _libraryService.syncLibrary(state: 'reading');
      }
    } catch (e) {
      if (e is AuthCancelledException) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  void _navigateToDetail(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeriesDetailScreen(series: series),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        return StreamBuilder<List<LibraryEntry>>(
          stream: _libraryService.watchEntriesFromDb(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ?? [];
            final currentlyReading = entries
                .where((e) => e.state.toLowerCase() == 'reading')
                .map((e) => e.series)
                .toList();

            // Sort by most recently updated first
            currentlyReading.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

            if (currentlyReading.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, color: AppConstants.textMutedColor, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('no_entries_category'),
                      style: TextStyle(color: AppConstants.textMutedColor),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _libraryService.syncLibrary(state: 'reading'),
              color: AppConstants.accentColor,
              backgroundColor: AppConstants.secondaryBackground,
              child: ListView.builder(
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
                      onTap: () => _navigateToDetail(series),
                      borderRadius: BorderRadius.circular(8),
                      child: EntryListItem(series: series),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
