import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/features/news/widgets/news_list_item.dart';

class NewsFeedGrid extends StatelessWidget {
  final ScrollController scrollController;
  final List<News> newsList;
  final bool isLoading;

  const NewsFeedGrid({
    super.key,
    required this.scrollController,
    required this.newsList,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < newsList.length; i += 2)
                      NewsListItem(
                        key: ValueKey('grid_${newsList[i].id}'),
                        news: newsList[i],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 1; i < newsList.length; i += 2)
                      NewsListItem(
                        key: ValueKey('grid_${newsList[i].id}'),
                        news: newsList[i],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: MbSpinner()),
            ),
        ],
      ),
    );
  }
}

class NewsFeedList extends StatelessWidget {
  final ScrollController scrollController;
  final List<News> newsList;
  final bool isLoading;

  const NewsFeedList({
    super.key,
    required this.scrollController,
    required this.newsList,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: newsList.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == newsList.length) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: MbSpinner()),
          );
        }
        return MbEntrance(
          index: index,
          child: NewsListItem(
            key: ValueKey('list_${newsList[index].id}'),
            news: newsList[index],
          ),
        );
      },
    );
  }
}

class NewsBackToTopFab extends StatelessWidget {
  final LocalizationService l10n;
  final ScrollController scrollController;

  const NewsBackToTopFab({
    super.key,
    required this.l10n,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return WidgetUtils.tooltip(
      message: l10n.translate('back_to_top'),
      child: FloatingActionButton(
        onPressed: () {
          scrollController.animateTo(
            0,
            duration: AppConstants.mediumAnimationDuration,
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: context.colors.accent,
        child: Icon(Icons.arrow_upward, color: context.colors.background),
      ),
    );
  }
}
