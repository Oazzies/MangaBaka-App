import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';

class SettingsCategoryScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCategoryScreen({
    super.key,
    required this.title,
    required this.children,
  });

  static void showAsDialog(
    BuildContext context, {
    required String title,
    required Widget content,
    VoidCallback? onBack,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _CategoryDialog(title: title, content: content, onBack: onBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppConstants.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: WidgetUtils.responsiveConstraint(
        ListView(
          padding: EdgeInsets.only(
            left: AppConstants.horizontalPadding,
            right: AppConstants.horizontalPadding,
            top: 8,
            bottom: 80,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onBack;

  const _CategoryDialog({
    required this.title,
    required this.content,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 64;
    return Dialog(
      backgroundColor: AppConstants.primaryBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                        onBack!();
                      },
                      color: AppConstants.textMutedColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppConstants.textMutedColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppConstants.borderColor),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppConstants.horizontalPadding,
                  right: AppConstants.horizontalPadding,
                  top: 16,
                  bottom: 24,
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
