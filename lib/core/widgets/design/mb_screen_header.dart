import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

PreferredSizeWidget mbScreenAppBar({
  required String title,

  bool isRoot = false,
  List<Widget> actions = const [],
  VoidCallback? onBack,
  PreferredSizeWidget? bottom,
  double fontSize = 20,
}) {
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
