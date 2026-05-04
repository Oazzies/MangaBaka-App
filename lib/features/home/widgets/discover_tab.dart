import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/settings/settings_enums.dart';
import 'package:bakahyou/features/series/widgets/series_list_skeleton.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Simulate loading for Discover
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final settings = SettingsManager();
        final isGrid = settings.currentListStyle == AppListStyle.grid || 
                       settings.currentListStyle == AppListStyle.coverOnlyGrid;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _isLoading
              ? SeriesListSkeleton(key: const ValueKey('skeleton'), isGrid: isGrid)
              : Center(
                  key: const ValueKey('content'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_outlined, color: AppConstants.textMutedColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate("discover_coming_soon") ?? "Discover feature coming soon!",
                        style: TextStyle(
                          color: AppConstants.textMutedColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
