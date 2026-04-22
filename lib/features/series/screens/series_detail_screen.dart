import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/series/widgets/state_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/widget_utils.dart';
import 'package:bakahyou/features/series/widgets/description_section.dart';
import 'package:bakahyou/features/series/widgets/series_detail_header.dart';
import 'package:bakahyou/features/series/widgets/rating_icon_button.dart';
import 'package:bakahyou/utils/di/service_locator.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late ScrollController _scrollController;
  bool _showTitle = false;
  late final LibraryService _libraryService;
  Stream<LibraryEntry?>? _entryStream;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _libraryService = getIt<LibraryService>();
    _scrollController.addListener(_onScroll);
    _entryStream = _libraryService.watchEntryFromDb(widget.series.id);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowTitle = _scrollController.offset > 200;
    if (shouldShowTitle != _showTitle) {
      setState(() => _showTitle = shouldShowTitle);
    }
  }

  void _shareLink() {
    String? mangabakaLink;
    for (var link in widget.series.links) {
      if (link is String && link.contains('mangabaka')) {
        mangabakaLink = link;
        break;
      }
    }

    if (mangabakaLink != null) {
      final box = context.findRenderObject() as RenderBox?;
      SharePlus.instance.share(
        ShareParams(
          text: mangabakaLink,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No MangaBaka link found for sharing.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.tertiaryBackground,
          title: Text(
            'Delete from Library',
            style: TextStyle(color: AppConstants.textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this series from your library?',
            style: TextStyle(color: AppConstants.textMutedColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppConstants.textColor),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Confirm', style: TextStyle(color: AppConstants.errorColor)),
              onPressed: () async {
                // First, pop the dialog.
                Navigator.of(dialogContext).pop();

                try {
                  await _libraryService.deleteEntry(widget.series.id);

                  // Then, if the widget is still mounted, pop the detail screen.
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppConstants.errorColor,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onStateChanged(String newState) async {
    try {
      await _libraryService.updateLibraryEntryState(widget.series.id, newState);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Library status updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}')),
      );
    }
  }

  Future<void> _onRatingChanged(int newRating) async {
    try {
      await _libraryService.updateLibraryEntryRating(
        widget.series.id,
        newRating,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rating updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating rating: ${e.toString()}')),
      );
    }
  }

  Future<void> _addSeriesToLibrary() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);

    try {
      await _libraryService.createLibraryEntry(
        widget.series.id,
        'plan_to_read',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add to library: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _showTitle ? Text(widget.series.title) : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareLink),
          StreamBuilder<LibraryEntry?>(
            stream: _entryStream,
            builder: (context, snapshot) {
              if (snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _showDeleteConfirmationDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<LibraryEntry?>(
          stream: _entryStream,
          builder: (context, snapshot) {
            final entry = snapshot.data;
            return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SeriesDetailHeader(
                      series: widget.series,
                      progressChapter: entry?.progressChapter,
                      progressVolume: entry?.progressVolume,
                      inLibrary: entry != null,
                    ),
                  ),
                  if (entry != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: StateSelectionSection(
                              currentState: entry.state,
                              onStateChanged: _onStateChanged,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RatingIconButton(
                            currentRating: entry.rating,
                            onRatingChanged: _onRatingChanged,
                          ),
                        ],
                      ),
                    ),
                  if (widget.series.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DescriptionSection(
                        description: widget.series.description,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WidgetUtils.chipWrap('Genres', widget.series.genres),
                        if (widget.series.authors.isNotEmpty)
                          WidgetUtils.chipWrap(
                            'Authors',
                            widget.series.authors,
                          ),
                        if (widget.series.artists.isNotEmpty)
                          WidgetUtils.chipWrap(
                            'Artists',
                            widget.series.artists,
                          ),
                        if (widget.series.publishers.isNotEmpty)
                          WidgetUtils.chipWrap(
                            'Publishers',
                            widget.series.publishers,
                          ),
                        if (widget.series.links.isNotEmpty)
                          WidgetUtils.linkList(widget.series.links),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: StreamBuilder<LibraryEntry?>(
        stream: _entryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active &&
              snapshot.data == null) {
            return FloatingActionButton.extended(
              onPressed: _isAdding ? null : _addSeriesToLibrary,
              label: _isAdding
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add to Library'),
              icon: _isAdding ? null : const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
