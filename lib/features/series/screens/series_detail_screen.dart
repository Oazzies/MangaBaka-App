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
import 'package:bakahyou/features/series/services/series_id_service.dart';
import 'package:bakahyou/features/series/widgets/series_detail_app_bar.dart';
import 'package:bakahyou/features/series/widgets/series_action_bar.dart';
import 'package:bakahyou/features/series/widgets/series_metadata_chips.dart';
import 'package:bakahyou/features/series/widgets/series_details_grid.dart';
import 'package:bakahyou/features/series/widgets/series_hero_cover.dart';

import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  @override
  void initState() {
    super.initState();
    _libraryService = getIt<LibraryService>();
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
    _fetchEnrichedLinks();
  }

  @override
  void didUpdateWidget(SeriesDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.id != widget.series.id) {
      _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
      _enrichedLinks = null;
      _fetchEnrichedLinks();
    }
  }

  Future<void> _fetchEnrichedLinks() async {
    try {
      final links = await SeriesService.fetchSeriesLinks(widget.series.id);
      if (mounted && links.isNotEmpty) {
        setState(() => _enrichedLinks = links);
      }
    } catch (e) {
      SeriesService.logger.warning('Error fetching enriched links: $e');
    }
  }

  void _shareLink() {
    final l10n = LocalizationService();
    String? link = widget.series.links.firstWhere(
      (l) => l is String && l.contains('mangabaka'), 
      orElse: () => null,
    ) as String?;

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
    final preferredTitle = widget.series.getDisplayTitle(settings.defaultTitleLanguage);
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
                            series: widget.series,
                            title: preferredTitle,
                            entry: entry,
                            isWide: isWide || isTablet,
                            onBack: () => Navigator.pop(context),
                            onShare: _shareLink,
                            onDelete: _showDeleteConfirmationDialog,
                            onCopy: _copyToClipboard,
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: isWide ? 40.0 : 16.0),
                              child: isWide 
                                ? _buildWideLayout(entry, l10n)
                                : _buildMobileLayout(entry, l10n),
                            ),
                          ),
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

  Widget _buildFAB(LocalizationService l10n) {
    return StreamBuilder<LibraryEntry?>(
      stream: _entryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active && snapshot.data == null) {
          return FloatingActionButton.extended(
            onPressed: _isAdding ? null : _addSeriesToLibrary,
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            label: _isAdding 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.translate('add_to_library'), style: const TextStyle(fontWeight: FontWeight.bold)),
            icon: _isAdding ? null : const Icon(Icons.add),
          ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobileLayout(LibraryEntry? entry, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesMetadataChips(series: widget.series, entry: entry)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        SeriesActionBar(
          entry: entry, 
          l10n: l10n,
          onStateChanged: (s) => _libraryService.updateLibraryEntryState(widget.series.id, s),
          onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(widget.series.id, r),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 20),
        if (widget.series.description.isNotEmpty) ...[
          _buildSectionHeader('Description').animate().fadeIn(delay: 200.ms),
          DescriptionSection(description: widget.series.description).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
        ],
        SeriesDetailsGrid(series: widget.series, enrichedLinks: _enrichedLinks, l10n: l10n)
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildWideLayout(LibraryEntry? entry, LocalizationService l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeriesHeroCover(series: widget.series, height: 420, width: 300)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              SeriesMetadataChips(series: widget.series, entry: entry, isVertical: true)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.1, end: 0),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeriesActionBar(
                entry: entry, 
                l10n: l10n,
                onStateChanged: (s) => _libraryService.updateLibraryEntryState(widget.series.id, s),
                onRatingChanged: (r) => _libraryService.updateLibraryEntryRating(widget.series.id, r),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 20),
              if (widget.series.description.isNotEmpty) ...[
                _buildSectionHeader('Description').animate().fadeIn(delay: 200.ms),
                DescriptionSection(description: widget.series.description).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 24),
              ],
              SeriesDetailsGrid(series: widget.series, enrichedLinks: _enrichedLinks, isWide: true, l10n: l10n)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
    );
  }

  Future<void> _addSeriesToLibrary() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      await _libraryService.createLibraryEntry(widget.series.id, SettingsManager().addLibraryDefaultTab);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
