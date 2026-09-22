import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The app's one screen-title treatment: uppercase display caps, centered with
/// a back chevron on pushed routes and left-aligned on tab roots, per the
/// reference's "ALL BOOKS" / "NOW" headers.
///
/// Returns an [AppBar] so it drops into any existing [Scaffold.appBar].
PreferredSizeWidget mbScreenAppBar({
  required String title,

  /// Left-aligns the title and drops the back chevron. Use on tab roots.
  bool isRoot = false,
  List<Widget> actions = const [],
  VoidCallback? onBack,
  PreferredSizeWidget? bottom,
  double fontSize = 20,
}) {
  // Colours come from the theme's appBarTheme (background, and the title
  // style's colour, which the display style below inherits).
  return AppBar(
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    leading: isRoot
        ? null
        : Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.text),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
    title: Text(
      title.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: AppTypography.display(fontSize: fontSize),
    ),
    actions: actions,
    bottom: bottom,
  );
}

/// In-page section header — the reference's "FOR YOU" / "ALL BOOKS" rail
/// labels, with an optional trailing arrow action.
class MbSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const MbSectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionIcon = Icons.arrow_forward_rounded,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppConstants.horizontalPadding,
      0,
      AppConstants.horizontalPadding,
      12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 17,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (onAction != null)
            IconButton(
              onPressed: onAction,
              visualDensity: VisualDensity.compact,
              icon: Icon(actionIcon, size: 20, color: context.colors.textMuted),
            ),
        ],
      ),
    );
  }
}
