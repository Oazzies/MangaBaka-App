import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/settings_category_screen.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';

class SettingsCategoryContent {
  final String title;
  final Widget content;

  const SettingsCategoryContent({required this.title, required this.content});
}

/// Lets [showOrNavigate] hand categories to the desktop settings page's right-hand pane.
class InlineSettingsHost extends InheritedWidget {
  final ValueChanged<SettingsCategoryContent> onOpen;

  const InlineSettingsHost({
    super.key,
    required this.onOpen,
    required super.child,
  });

  static InlineSettingsHost? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<InlineSettingsHost>();

  @override
  bool updateShouldNotify(InlineSettingsHost oldWidget) => false;
}

/// Landscape pages inside the settings dialog: a pushed route would cover it as if it vanished.
void showOrNavigate(
  BuildContext context, {
  required String title,
  Listenable? listenable,
  required List<Widget> Function(BuildContext) buildChildren,
}) {
  final host = InlineSettingsHost.maybeOf(context);
  final isLandscape =
      host == null &&
      MediaQuery.orientationOf(context) == Orientation.landscape;

  Widget buildInner(BuildContext ctx) {
    final children = buildChildren(ctx);
    // The dialog and desktop pane already scroll and carry a header, so only the rows go in.
    return isLandscape || host != null
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : SettingsCategoryScreen(title: title, children: children);
  }

  final content = listenable != null
      ? ListenableBuilder(
          listenable: listenable,
          builder: (ctx, _) => buildInner(ctx),
        )
      : Builder(builder: buildInner);

  if (host != null) {
    host.onOpen(SettingsCategoryContent(title: title, content: content));
    return;
  }

  if (!isLandscape) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => content));
    return;
  }

  final dialogState = SettingsDialog.of(context);
  if (dialogState != null) {
    dialogState.pushCategory(title, content);
    return;
  }

  _showAsStandaloneDialog(context, title: title, content: content);
}

/// Deferred a frame so the replacement does not overlap the dialog being popped.
void _showAsStandaloneDialog(
  BuildContext context, {
  required String title,
  required Widget content,
}) {
  Navigator.pop(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final rootContext = AppConstants.navigatorKey.currentContext;
    if (rootContext == null) return;
    SettingsCategoryScreen.showAsDialog(
      rootContext,
      title: title,
      content: content,
      onBack: () {
        final ctx = AppConstants.navigatorKey.currentContext;
        if (ctx != null) SettingsScreen.show(ctx);
      },
    );
  });
}
