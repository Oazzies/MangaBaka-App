import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/description_section.dart';
import 'package:bakahyou/utils/di/service_locator.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/features/series/models/series_link.dart';
import 'package:bakahyou/features/series/models/series_cover.dart';
import 'package:bakahyou/features/news/models/news.dart';
import 'package:bakahyou/features/series/models/series_collection.dart';
import 'package:bakahyou/features/series/models/series_work.dart';
import 'package:bakahyou/features/series/services/series_id_service.dart';
import 'package:bakahyou/features/series/widgets/series_detail_app_bar.dart';
import 'package:bakahyou/features/series/widgets/series_action_bar.dart';
import 'package:bakahyou/features/series/widgets/series_metadata_chips.dart';
import 'package:bakahyou/features/series/widgets/series_details_grid.dart';
import 'package:bakahyou/features/series/widgets/series_hero_cover.dart';
import 'package:bakahyou/features/series/widgets/series_segmented_control.dart';
import 'package:bakahyou/features/series/widgets/series_genres_section.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';
import 'package:bakahyou/features/series/widgets/tabs/series_covers_tab.dart';
import 'package:bakahyou/features/series/widgets/tabs/series_related_tab.dart';
import 'package:bakahyou/features/series/widgets/tabs/series_news_tab.dart';
import 'package:bakahyou/features/series/widgets/tabs/series_collections_tab.dart';
import 'package:bakahyou/features/series/widgets/tabs/series_works_tab.dart';

import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bakahyou/features/series/widgets/series_detail_skeleton.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late final LibraryService _libraryService;
  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;
  List<SeriesLink>? _enrichedLinks;
  Series? _fullSeries;
  bool _isDataLoaded = false;
  bool _fetchError = false;

  String _selectedTab = 'Information';
  List<SeriesCover>? _covers;
  List<Series>? _related;
  List<News>? _news;
  List<SeriesCollection>? _collections;
  List<SeriesWork>? _works;

  @override
  void initState() {
    super.initState();
    _libraryService = getIt<LibraryService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    _fullSeries = widget.series; 
    _fetchFullData();
  }

  Future<void> _fetchExtraData() async {
    final id = widget.series.id;
    SeriesService.fetchSeriesCovers(id).then((v) { if (mounted) setState(() => _covers = v); });
    SeriesService.fetchSeriesRelated(id).then((v) { if (mounted) setState(() => _related = v); });
    SeriesService.fetchSeriesNews(id).then((v) { if (mounted) setState(() => _news = v); });
    SeriesService.fetchSeriesCollections(id).then((v) { if (mounted) setState(() => _collections = v); });
    SeriesService.fetchSeriesWorks(id).then((v) { if (mounted) setState(() => _works = v); });
  }

  Future<void> _fetchFullData() async {
    try {
      _fetchExtraData(); 

      final results = await Future.wait([
        SeriesService.fetchSeriesLinks(widget.series.id),
        SeriesService.fetchSeries(widget.series.id),
      ]);
      
      if (mounted) {
        setState(() {
          _enrichedLinks = results[0] as List<SeriesLink>?;
          _fullSeries = results[1] as Series?;
          _isDataLoaded = true;
          _fetchError = false;
        });
      }
    } catch (e) {
      SeriesService.logger.warning('Error fetching full data: $e');
      if (mounted) {
        setState(() {
          _isDataLoaded = true; 
          _fetchError = true;
        });
      }
    }
  }

  void _shareLink() {
    final l10n = LocalizationService();
    final String? link = widget.series.links
        .whereType<String>()
        .where((l) => l.contains('mangabaka'))
        .firstOrNull;

    if (link != null) {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.instance.share(ShareParams(
        text: link,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('no_sharing_link'))));
    }
  }

  void _showDeleteConfirmationDialog() {
    final l10n = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.tertiaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('delete_from_library'), style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold)),
        content: Text(l10n.translate('delete_confirmation'), style: TextStyle(color: AppConstants.textMutedColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'), style: TextStyle(color: AppConstants.textColor))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _libraryService.deleteEntry(widget.series.id);
              if (mounted) Navigator.pop(this.context);
            },
            child: Text(l10n.translate('confirm'), style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied "$text" to clipboard'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 15) Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: AppConstants.primaryBackground,
            body: StreamBuilder<LibraryEntry?>(
              stream: _entryStream,
              builder: (context, snapshot) {
                final entry = snapshot.data;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: RepaintBoundary(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SeriesDetailAppBar(
                            series: _fullSeries ?? widget.series,
                            title: (_fullSeries ?? widget.series).getDisplayTitle(settings.defaultTitleLanguage),
                            entry: entry,
                            isWide: isWide || isTablet,
                            isLoaded: _isDataLoaded,
                            onBack: () => Navigator.pop(context),
                            onShare: _shareLink,
                            onDelete: _showDeleteConfirmationDialog,
                            onCopy: _copyToClipboard,
                          ),
                          if (_fetchError)
                            _buildErrorBanner(),
                          SliverToBoxAdapter(
                            child: isWide 
                              ? _buildWideLayout(entry, l10n)
                              : _buildMobileLayout(entry, l10n),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButton: _buildFAB(l10n),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppConstants.errorColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not load full details. Showing partial data.',
                  style: TextStyle(color: AppConstants.errorColor, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDataLoaded = false;
                    _fetchError = false;
                  });
                  _fetchFullData();
                },
                child: Text('Retry', style: TextStyle(color: AppConstants.errorColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(LocalizationService l10n) {
    return StreamBuilder<LibraryEntry?>(
      stream: _entryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active && snapshot.data == null) {
          return FloatingActionButton.extended(
            onPressed: _isAdding ? null : _addSeriesToLibrary,
            backgroundColor: AppConstants.accentColor,
            foregroundColor: AppConstants.primaryBackground,
            label: _isAdding 
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryBackground))
              : Text(l10n.translate('add_to_library'), style: const TextStyle(fontWeight: FontWeight.bold)),
            icon: _isAdding ? null : const Icon(Icons.add),
          ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobileLayout(LibraryEntry? entry, LocalizationService l10n) {
    final series = _fullSeries ?? widget.series;
    const hPadding = 16.0;
    
    return AnimatedSwitcher(
      duration: 600.ms,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _isDataLoaded 
        ? Column(
            key: const ValueKey('full_layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SeriesMetadataChips(series: series, entry: entry),
                    const SizedBox(height: 16),
                    SeriesActionBar(
                      entry: entry, 
                      l10n: l10n,
                      onStateChanged: (s) => _libraryService.updateLibraryEntryState(series.id, s),
                      onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(series.id, r),
                    ),
                    const SizedBox(height: 20),
                    if (series.description.isNotEmpty) ...[
                      const SeriesSectionHeader(title: 'Description'),
                      DescriptionSection(description: series.description),
                      const SizedBox(height: 20),
                    ],
                    SeriesGenresSection(series: series, l10n: l10n),
                    SeriesSegmentedControl(
                      selectedTab: _selectedTab,
                      onTabChanged: (tab) => setState(() => _selectedTab = tab),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTabContent(series, entry, l10n, hPadding: hPadding),
            ],
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic)
        : const Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Column(
              key: ValueKey('skeleton_layout'),
              children: [
                SeriesDetailSkeleton(),
                SizedBox(height: 400),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildWideLayout(LibraryEntry? entry, LocalizationService l10n) {
    final series = _fullSeries ?? widget.series;
    const hPadding = 40.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: hPadding),
          child: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeriesHeroCover(series: series, height: 420, width: 300),
                const SizedBox(height: 32),
                if (_isDataLoaded)
                  SeriesMetadataChips(series: series, entry: entry, isVertical: true)
                      .animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: AnimatedSwitcher(
            duration: 600.ms,
            child: _isDataLoaded 
              ? Column(
                  key: const ValueKey('wide_full_layout'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: hPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SeriesActionBar(
                            entry: entry, 
                            l10n: l10n,
                            onStateChanged: (s) => _libraryService.updateLibraryEntryState(series.id, s),
                            onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(series.id, r),
                          ),
                          const SizedBox(height: 20),
                          if (series.description.isNotEmpty) ...[
                            const SeriesSectionHeader(title: 'Description'),
                            DescriptionSection(description: series.description),
                            const SizedBox(height: 24),
                          ],
                          SeriesGenresSection(series: series, l10n: l10n),
                          SeriesSegmentedControl(
                            selectedTab: _selectedTab,
                            onTabChanged: (tab) => setState(() => _selectedTab = tab),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTabContent(series, entry, l10n, isWide: true, hPadding: hPadding, wideRightPaddingOnly: true),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic)
              : Padding(
                  padding: const EdgeInsets.only(right: hPadding),
                  child: const SeriesDetailSkeleton(key: ValueKey('wide_skeleton'), isWide: true),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(Series series, LibraryEntry? entry, LocalizationService l10n, {bool isWide = false, double hPadding = 16.0, bool wideRightPaddingOnly = false}) {
    // For News, we want 0 horizontal padding because NewsListItem already has horizontal margin.
    // However, the header still needs padding.
    final tabPadding = _selectedTab == 'News' ? 0.0 : hPadding;
    // For wide layout, the padding is usually only on the right for the tab content in this column.
    
    switch (_selectedTab) {
      case 'Covers':
        return SeriesCoversTab(covers: _covers, horizontalPadding: tabPadding);
      case 'Related':
        return SeriesRelatedTab(related: _related, l10n: l10n, horizontalPadding: tabPadding);
      case 'News':
        return SeriesNewsTab(news: _news, horizontalPadding: hPadding); // Pass hPadding for the header, items handle themselves
      case 'Collections':
        return SeriesCollectionsTab(collections: _collections, horizontalPadding: tabPadding);
      case 'Works':
        return SeriesWorksTab(works: _works, horizontalPadding: tabPadding);
      case 'Information':
      default:
        return SeriesDetailsGrid(series: series, enrichedLinks: _enrichedLinks, l10n: l10n, isWide: isWide, horizontalPadding: tabPadding);
    }
  }

  Future<void> _addSeriesToLibrary() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      await _libraryService.createLibraryEntry(widget.series.id, SettingsManager().addLibraryDefaultTab);
    } catch (e) {
      SeriesService.logger.warning('Failed to add series to library: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to library. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

