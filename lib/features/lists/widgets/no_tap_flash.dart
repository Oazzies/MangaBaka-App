import 'package:flutter/material.dart';

/// Rows whose own mark (spinner, check) already answers the tap.
class NoTapFlash extends StatelessWidget {
  final Widget child;

  const NoTapFlash({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    child: child,
  );
}
