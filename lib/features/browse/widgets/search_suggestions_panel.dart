import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class SearchSuggestionsPanel extends StatelessWidget {
  final List<AutocompleteSeriesResult> results;
  final ValueChanged<AutocompleteSeriesResult> onResultTapped;
  final bool showSuggestions;

  const SearchSuggestionsPanel({
    super.key,
    required this.results,
    required this.onResultTapped,
    required this.showSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: showSuggestions ? _buildSuggestionsList() : const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppConstants.borderColor.withValues(alpha: 0.4),
            indent: 16,
            endIndent: 16,
          ),
          ...List.generate(results.length, (index) {
            final result = results[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultTile(result),
                if (index < results.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppConstants.borderColor.withValues(alpha: 0.2),
                    indent: 68,
                    endIndent: 16,
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultTile(AutocompleteSeriesResult result) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onResultTapped(result),
        splashColor: AppConstants.accentColor.withValues(alpha: 0.08),
        highlightColor: AppConstants.accentColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 36,
                  height: 50,
                  child: result.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          result.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildThumbnailPlaceholder(),
                        )
                      : _buildThumbnailPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.title,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: AppConstants.textMutedColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: AppConstants.tertiaryBackground,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppConstants.textMutedColor,
        size: 18,
      ),
    );
  }
}
