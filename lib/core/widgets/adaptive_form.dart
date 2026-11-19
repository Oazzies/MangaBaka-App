import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

/// A page on phones, where the keyboard would resize a bottom sheet's viewport; a dialog elsewhere.
Future<T?> showAdaptiveForm<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  bool scrollable = true,
  BoxConstraints? constraints,
}) {
  if (prefersDialogSheet(context)) {
    return showAdaptiveSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: constraints,
      builder: builder,
    );
  }
  return Navigator.of(context).push<T>(
    AppTransitions.slideUp(
      AdaptiveFormPage(title: title, scrollable: scrollable, builder: builder),
    ),
  );
}

class AdaptiveFormPage extends StatelessWidget {
  final String title;
  final bool scrollable;
  final WidgetBuilder builder;

  const AdaptiveFormPage({
    super.key,
    required this.title,
    required this.builder,
    this.scrollable = true,
  });

  /// True inside a page, where a form drops its sheet chrome (handle, title row, rounded surface).
  static bool isPage(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AdaptiveFormPageScope>() !=
      null;

  @override
  Widget build(BuildContext context) {
    // The Scaffold already resizes for the keyboard; the form's own inset would count it twice.
    final body = MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: _AdaptiveFormPageScope(child: Builder(builder: builder)),
    );
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(title: title),
      body: SafeArea(
        top: false,
        child: scrollable ? SingleChildScrollView(child: body) : body,
      ),
    );
  }
}

class _AdaptiveFormPageScope extends InheritedWidget {
  const _AdaptiveFormPageScope({required super.child});

  @override
  bool updateShouldNotify(_AdaptiveFormPageScope oldWidget) => false;
}
