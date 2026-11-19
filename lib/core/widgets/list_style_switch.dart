import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// [run] flips [switching] first so the heavy rebuild runs behind a skeleton.
abstract final class ListStyleSwitch {
  static final ValueNotifier<bool> switching = ValueNotifier(false);
  static Timer? _settle;

  static Future<void> run(VoidCallback apply) async {
    _settle?.cancel();
    switching.value = true;
    await WidgetsBinding.instance.endOfFrame;
    apply();
    _settle?.cancel();
    _settle = Timer(
      const Duration(milliseconds: 140),
      () => switching.value = false,
    );
  }
}

class ListStyleSwitchGate extends StatelessWidget {
  final Widget child;

  final bool nestedInScrollView;

  const ListStyleSwitchGate({
    super.key,
    required this.child,
    this.nestedInScrollView = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ListStyleSwitch.switching,
      builder: (context, switching, _) =>
          switching ? _SwitchSkeleton(nested: nestedInScrollView) : child,
    );
  }
}

class _SwitchSkeleton extends StatelessWidget {
  final bool nested;

  const _SwitchSkeleton({this.nested = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: nested,
      padding: nested ? EdgeInsets.zero : const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: nested ? 9 : 24,
      itemBuilder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppConstants.denseRadius),
        ),
      ),
    );
  }
}
