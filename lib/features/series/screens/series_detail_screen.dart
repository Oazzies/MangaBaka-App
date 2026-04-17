import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/series/widgets/state_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/widget_utils.dart';
import 'package:bakahyou/features/series/widgets/description_section.dart';
import 'package:bakahyou/features/series/widgets/series_detail_header.dart';
import 'package:bakahyou/features/series/widgets/rating_icon_button.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({Key? key, required this.series}) : super(key: key);

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late ScrollController _scrollController;
  bool _showTitle = false;
  final LibraryService _libraryService = LibraryService();
  Stream<LibraryEntry?>? _entryStream;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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

  Future<void> _onStateChanged(String newState) async {
    try {
      await _libraryService.updateLibraryEntryState(widget.series.id, newState);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Library status updated!')));
    } catch (e) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rating updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating rating: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showTitle ? Text(widget.series.title) : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareLink),
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
    );
  }
}
