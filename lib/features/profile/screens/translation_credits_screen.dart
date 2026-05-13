import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class TranslationCreditsScreen extends StatelessWidget {
  const TranslationCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final languages = l10n.getLanguages();

    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('translation_credits'),
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: AppConstants.primaryBackground,
        iconTheme: IconThemeData(color: AppConstants.textColor),
        centerTitle: true,
        elevation: 0,
      ),
      body: WidgetUtils.responsiveConstraint(
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final translators = lang['translators'] as List<String>;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppConstants.secondaryBackground,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          lang['name'],
                          style: TextStyle(
                            color: AppConstants.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${lang['code']})',
                          style: TextStyle(
                            color: AppConstants.textMutedColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.transparent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: translators.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: AppConstants.textMutedColor,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
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
