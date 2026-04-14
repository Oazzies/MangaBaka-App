import 'package:flutter/material.dart';
import 'package:mangabaka_app/models/series.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';
import 'package:mangabaka_app/features/series/widgets/description_section.dart';
import 'package:mangabaka_app/features/series/widgets/expandable_chip_wrap.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_header.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({Key? key, required this.series}) : super(key: key);

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowTitle = _scrollController.offset > 0;
    if (shouldShowTitle != _showTitle) {
      setState(() => _showTitle = shouldShowTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showTitle ? Text(widget.series.title) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border),
            onPressed: () {},
            tooltip: 'Save to Library',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
            tooltip: 'Share',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SeriesDetailHeader(series: widget.series),
              const SizedBox(height: 38),
              if (widget.series.description.isNotEmpty)
                DescriptionSection(description: widget.series.description),
              const SizedBox(height: 8),
              WidgetUtils.chipWrap('Genres', widget.series.genres),
              const SizedBox(height: 8),
              if (widget.series.authors.isNotEmpty)
                WidgetUtils.chipWrap('Authors', widget.series.authors),
              const SizedBox(height: 8),
              if (widget.series.artists.isNotEmpty)
                WidgetUtils.chipWrap('Artists', widget.series.artists),
              const SizedBox(height: 8),
              if (widget.series.publishers.isNotEmpty)
                WidgetUtils.chipWrap('Publishers', widget.series.publishers),
              const SizedBox(height: 8),
              ExpandableChipWrap(label: 'Tags', items: widget.series.tags),
              const SizedBox(height: 8),
              if (widget.series.links.isNotEmpty)
                WidgetUtils.linkList(widget.series.links),
            ],
          ),
        ),
      ),
    );
  }
}