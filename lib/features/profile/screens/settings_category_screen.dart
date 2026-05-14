import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/widget_utils.dart';

class SettingsCategoryScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCategoryScreen({
    super.key,
    required this.title,
    required this.children,
  });

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
          style: TextStyle(color: AppConstants.textColor),
        ),
        backgroundColor: AppConstants.primaryBackground,
        iconTheme: IconThemeData(color: AppConstants.textColor),
        centerTitle: true,
        elevation: 0,
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
