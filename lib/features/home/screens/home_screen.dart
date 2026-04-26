import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

import 'package:bakahyou/features/home/widgets/activity_tab.dart';
import 'package:bakahyou/features/home/widgets/current_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppConstants.primaryBackground,
            appBar: AppBar(
              backgroundColor: AppConstants.primaryBackground,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                l10n.translate("home"),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              centerTitle: false,
              actions: [
                // Padding(
                //   padding: const EdgeInsets.only(right: 8.0),
                //   child: IconButton(
                //     icon: Icon(
                //       Icons.notifications_outlined, 
                //       color: AppConstants.textColor,
                //       size: 28,
                //     ),
                //     onPressed: () {
                //       // Static notification button as requested
                //     },
                //   ),
                // ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  isScrollable: false,
                  indicatorColor: AppConstants.accentColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppConstants.textColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelColor: AppConstants.textMutedColor,
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  dividerColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: [
                    Tab(text: l10n.translate("discover")),
                    Tab(text: l10n.translate("current")),
                    Tab(text: l10n.translate("activity")),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildPlaceholderContent(l10n.translate("discover")),
                const CurrentTab(),
                const ActivityTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.textMutedColor,
          fontSize: 18,
        ),
      ),
    );
  }
}
