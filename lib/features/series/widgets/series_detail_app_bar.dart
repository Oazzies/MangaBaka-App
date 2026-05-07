import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/features/series/widgets/series_hero_cover.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeriesDetailAppBar extends StatelessWidget {
  final Series series;
  final String title;
  final LibraryEntry? entry;
  final bool isWide;
  final bool isLoaded;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Function(String) onCopy;

  const SeriesDetailAppBar({
    super.key,
    required this.series,
    required this.title,
    this.entry,
    required this.isWide,
    required this.isLoaded,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final double expandedHeight = isWide ? 400 : 320;
    
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // Approximate collapse detection
        final double offset = constraints.scrollOffset;
        final bool isCollapsed = offset > (expandedHeight - 100);
        final isDark = ThemeManager().isDarkMode;
        
        // Colors that adapt to collapse state
        final Color buttonForeground = isCollapsed 
            ? AppConstants.textColor 
            : (isDark ? AppConstants.textColor : Colors.white);
            
        final Color? buttonBackground = (isCollapsed || isDark) 
            ? null 
            : Colors.black.withValues(alpha: 0.3);

        final buttonStyle = IconButton.styleFrom(
          foregroundColor: buttonForeground,
          backgroundColor: buttonBackground,
          minimumSize: const Size(40, 40),
          maximumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        );

        return SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          backgroundColor: AppConstants.primaryBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                style: buttonStyle,
              ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onShare,
              style: buttonStyle,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            if (entry != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                style: buttonStyle,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
            centerTitle: false,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 600 : 200),
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                if (series.coverUrl.isNotEmpty)
                  Image.network(
                    series.coverUrl,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: isWide ? 1200 : 800,
                  ).animate(target: isLoaded ? 1 : 0)
                   .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                   .scale(begin: const Offset(1.05, 1.05), end: const Offset(1, 1), curve: Curves.easeOut),
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ).animate(target: isLoaded ? 1 : 0)
                 .fadeIn(duration: 1200.ms, curve: Curves.easeOut),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppConstants.primaryBackground.withValues(alpha: 0),
                        AppConstants.primaryBackground.withValues(alpha: 0.4),
                        AppConstants.primaryBackground.withValues(alpha: 0.9),
                        AppConstants.primaryBackground,
                      ],
                      stops: const [0.0, 0.5, 0.85, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SeriesHeroCover(
                        series: series,
                        height: isWide ? 220 : 180,
                        width: isWide ? 150 : 125,
                      ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMainInfo(context, isDark)
                            .animate(target: isLoaded ? 1 : 0)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainInfo(BuildContext context, bool isDark) {
    final otherTitles = <String>[];
    if (series.title.isNotEmpty && series.title != title) {
      otherTitles.add(series.title);
    }
    if (series.nativeTitle.isNotEmpty && 
        series.nativeTitle != title && 
        !otherTitles.contains(series.nativeTitle)) {
      otherTitles.add(series.nativeTitle);
    }
    if (series.romanizedTitle.isNotEmpty && 
        series.romanizedTitle != title && 
        !otherTitles.contains(series.romanizedTitle)) {
      otherTitles.add(series.romanizedTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onCopy(title),
          borderRadius: BorderRadius.circular(4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isWide ? 32 : 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
              height: 1.1,
              shadows: [
                Shadow(
                  color: AppConstants.primaryBackground.withValues(alpha: 0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (otherTitles.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...otherTitles.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () => onCopy(t),
              borderRadius: BorderRadius.circular(4),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: isWide ? 15 : 13,
                  color: AppConstants.textMutedColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
        ],
      ],
    );
  }
}
