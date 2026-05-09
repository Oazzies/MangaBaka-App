import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final l10n = LocalizationService();
        
        return Scaffold(
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
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_outlined, color: AppConstants.textMutedColor, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.translate("discover_coming_soon") ?? "Discover feature coming soon!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppConstants.textMutedColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
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
