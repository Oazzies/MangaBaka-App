import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_title_bar.dart';

/// Wraps the application with custom window controls overlaid directly at the
/// top of the application on supported desktop platforms (primarily Windows).
///
/// On desktop, the entire app content fills the window from top to bottom
/// (`y = 0`), with the custom window controls floating in the top-right corner
/// and a draggable top region, rather than pushing the application down below
/// a separate bar.
class DesktopWindowFrame extends StatefulWidget {
  final Widget child;

  @visibleForTesting
  static bool? debugOverride;

  /// Set to true by full-window modal screens (like desktop onboarding) that
  /// provide their own dedicated sticky top bar with window controls.
  static final ValueNotifier<bool> hideTitleBar = ValueNotifier<bool>(false);

  static bool get isSupported {
    final override = debugOverride;
    if (override != null) return override;
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  const DesktopWindowFrame({super.key, required this.child});

  @override
  State<DesktopWindowFrame> createState() => _DesktopWindowFrameState();
}

class _DesktopWindowFrameState extends State<DesktopWindowFrame> {
  late final ValueNotifier<Widget> _childNotifier;
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _childNotifier = ValueNotifier<Widget>(widget.child);
    _entry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Widget>(
        valueListenable: _childNotifier,
        builder: (context, child, _) => Stack(
          children: [
            Positioned.fill(child: child),
            ValueListenableBuilder<bool>(
              valueListenable: DesktopWindowFrame.hideTitleBar,
              builder: (context, hide, _) {
                if (hide) return const SizedBox.shrink();
                // Kept clear of the sidebar: it floats only over the main
                // content area, never over the sidebar's own top (logo,
                // collapse arrow), and slides in step with its collapse
                // animation.
                return ValueListenableBuilder<double>(
                  valueListenable: DesktopShell.sidebarInset,
                  builder: (context, sidebarInset, _) => AnimatedPositioned(
                    duration: AppMotion.base,
                    curve: AppMotion.emphasized,
                    top: 0,
                    left: sidebarInset,
                    right: 0,
                    child: const DesktopTitleBar(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(DesktopWindowFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _childNotifier.value = widget.child;
    }
  }

  @override
  void dispose() {
    _childNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopWindowFrame.isSupported) return widget.child;

    return Overlay(initialEntries: [_entry]);
  }
}
