import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/collections/screens/collections_browse_screen.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/screens/publisher_detail_screen.dart';
import 'package:mangabaka_app/features/publisher/widgets/publisher_list_item.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';
import 'package:mangabaka_app/features/staff/widgets/staff_list_item.dart';

class BrowsePeopleResults extends StatelessWidget {
  final List<dynamic> searchResults;
  final BrowseType browseType;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final void Function(String, String, {String? staff}) onNavigateToResults;

  const BrowsePeopleResults({
    super.key,
    required this.searchResults,
    required this.browseType,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onNavigateToResults,
  });

  @override
  Widget build(BuildContext context) {
    final cellHeight = browseType == BrowseType.publishers ? 136.0 : 88.0;
    final itemCount = searchResults.length + (isLoadingMore ? 1 : 0);

    Widget spinner() => const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: MbSpinner()),
    );

    Widget buildItem(BuildContext context, int index, EdgeInsetsGeometry? margin) {
      if (browseType == BrowseType.publishers) {
        final publisher = searchResults[index] as Publisher;
        return PublisherListItem(
          publisher: publisher,
          margin: margin,
          onTap: () => PublisherDetailScreen.open(
            context,
            id: publisher.id,
            publisher: publisher,
          ),
        );
      }
      final staff = searchResults[index] as Staff;
      return StaffListItem(
        staff: staff,
        margin: margin,
        onTap: () =>
            onNavigateToResults(staff.name, 'popularity_desc', staff: staff.name),
      );
    }

    if (DesktopLayout.isActive(context)) {
      return GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 460,
          mainAxisExtent: cellHeight,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => index >= searchResults.length
            ? spinner()
            : buildItem(context, index, EdgeInsets.zero),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) => index >= searchResults.length
          ? spinner()
          : buildItem(context, index, null),
    );
  }
}

class BrowseEmptyPrompt extends StatelessWidget {
  final BrowseType browseType;
  final LocalizationService l10n;

  const BrowseEmptyPrompt({
    super.key,
    required this.browseType,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (browseType == BrowseType.publishers) {
      return Center(
        key: const ValueKey('publishers_prompt'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_rounded,
              size: 64,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('search_publishers_hint'),
              style: AppTypography.sans(
                color: context.colors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.collections_bookmark_rounded, size: 18),
              label: Text(l10n.translate('collections_and_editions')),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.accent,
                side: BorderSide(color: context.colors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => CollectionsBrowseScreen.open(context),
            ),
          ],
        ),
      );
    }

    final icon = switch (browseType) {
      BrowseType.publishers => Icons.business,
      BrowseType.staff => Icons.people,
      _ => Icons.search,
    };

    return Center(
      key: const ValueKey('search_prompt'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: context.colors.textMuted),
          const SizedBox(height: 16),
          Text(
            l10n.translate('no_results'),
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class BrowseErrorState extends StatelessWidget {
  final String? error;
  final LocalizationService l10n;
  final VoidCallback onRetry;

  const BrowseErrorState({
    super.key,
    required this.error,
    required this.l10n,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: context.colors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            error ?? 'An unexpected error occurred.',
            style: AppTypography.sans(color: context.colors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.translate('retry')),
          ),
        ],
      ),
    );
  }
}
