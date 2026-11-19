import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// [run] flips [switching] first so the heavy rebuild runs behind a skeleton.
abstract final class ListStyleSwitch {
  static final ValueNotifier<bool> switching = ValueNotifier(false);

  static Future<void> run(VoidCallback apply) async {
    switching.value = true;
    await WidgetsBinding.instance.endOfFrame;
    apply();
    await Future<void>.delayed(const Duration(milliseconds: 140));
    switching.value = false;
  }
}

class ListStyleSwitchGate extends StatelessWidget {
  final Widget child;

  final bool shrink;

  const ListStyleSwitchGate({
    super.key,
    required this.child,
    this.shrink = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ListStyleSwitch.switching,
      builder: (context, switching, _) =>
          switching ? _SwitchSkeleton(shrink: shrink) : child,
    );
  }
}

class _SwitchSkeleton extends StatelessWidget {
  final bool shrink;

  const _SwitchSkeleton({this.shrink = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: shrink,
      padding: shrink ? EdgeInsets.zero : const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: shrink ? 9 : 24,
      itemBuilder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      ),
    );
  }
}
