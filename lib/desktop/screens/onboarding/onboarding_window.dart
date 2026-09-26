import 'package:flutter/painting.dart';
import 'package:window_manager/window_manager.dart';

/// Pins the desktop window to a fixed, centred size while onboarding is open.
///
/// Onboarding is a single composed screen, not a responsive page: stretched
/// across a 4K monitor it stops reading as a step-by-step flow. So it gets a
/// window of its own shape, and the user's previous window is put back when it
/// closes.
class OnboardingWindow {
  OnboardingWindow._();

  /// Tall enough for the app's minimum window height, wide enough for the
  /// brand panel plus a comfortable content column.
  static const Size size = Size(1040, 720);

  static Size? _previousSize;

  static Future<void> enter() async {
    try {
      if (await windowManager.isFullScreen()) {
        await windowManager.setFullScreen(false);
      }
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      }
      _previousSize ??= await windowManager.getSize();
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimumSize(size);
      await windowManager.setMaximumSize(size);
      await windowManager.setSize(size);
      await windowManager.center();
    } catch (_) {
      // Window sizing is cosmetic; onboarding works in any window.
    }
  }

  static Future<void> exit() async {
    try {
      await windowManager.setMinimumSize(Size.zero);
      await windowManager.setMaximumSize(Size.zero);
      await windowManager.setResizable(true);
      await windowManager.setMaximizable(true);
      final previous = _previousSize;
      _previousSize = null;
      if (previous != null) {
        await windowManager.setSize(previous);
        await windowManager.center();
      }
    } catch (_) {}
  }
}
