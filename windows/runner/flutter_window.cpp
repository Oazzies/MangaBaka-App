#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Windows 11 rounds top-level windows itself, but one whose frame has been
// extended into the client area — as this window's is — is left square unless
// it asks. Both values are defined here because the SDK in use may predate
// Windows 11; older Windows simply rejects the attribute and the call is a
// harmless no-op.
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
constexpr int kDwmcpRound = 2;
constexpr int kDwmcpDoNotRound = 1;

// Rounds the window's corners while it is a normal floating window. Fullscreen
// drops the frame style (see the style-change handler below), and there the
// corners are squared so nothing is clipped at the monitor edges; maximized
// windows are squared by DWM on its own.
void ApplyWindowCornerPreference(HWND window, bool rounded) {
  int preference = rounded ? kDwmcpRound : kDwmcpDoNotRound;
  DwmSetWindowAttribute(window, DWMWA_WINDOW_CORNER_PREFERENCE, &preference,
                        sizeof(preference));
}

// Smallest client area, in logical pixels, the window may be sized to. The
// width is DesktopLayout.minWidth (lib/desktop/desktop_layout.dart): below it
// the app falls back to its mobile layouts, which the desktop window never
// shows. Keep the two in step.
constexpr SIZE kMinimumClientSize = {1000, 700};

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  ApplyWindowCornerPreference(GetHandle(), true);

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Sizes the client area of the floating (framed, not maximized) window
  // before window_manager sees the message. Its TitleBarStyle.hidden handling
  // insets the client by a fixed 8 physical pixels, but the resize border is
  // DPI-dependent (about 11px at 150%), so the frame DWM keeps no longer
  // matches the real border. The default frame gives exact borders at any DPI;
  // only the caption is removed by restoring the top edge. Maximized and
  // fullscreen windows are left to the plugin.
  //
  // WM_NCPAINT must reach DefWindowProc as well: swallowing it stops DWM
  // treating the border as its invisible resize frame, and the strip is then
  // shown as part of the window without ever being painted. It keeps whatever
  // stale pixels were there — white bars, background colour, or old copies of
  // widgets along the left, right and bottom edges. With no caption left in
  // the non-client area there is no native title bar for it to draw.
  if (message == WM_NCCALCSIZE && wparam) {
    const LONG style = GetWindowLong(hwnd, GWL_STYLE);
    if ((style & WS_CAPTION) == WS_CAPTION && !IsZoomed(hwnd)) {
      auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      const LONG top = params->rgrc[0].top;
      DefWindowProc(hwnd, message, wparam, lparam);
      params->rgrc[0].top = top;
      return 0;
    }
  }

  switch (message) {
    // Kept away from window_manager. On a DPI change — dragging the window to
    // a monitor with different scaling — it resizes the Flutter view 1px wider
    // and back to "refresh" it, and the engine blocks this thread for a full
    // frame on each resize. That doubled the freeze at every monitor crossing.
    // Its only other use of the message is the scale for its minimum-size
    // clamp, which is handled below instead. Win32Window applies the new size.
    case WM_DPICHANGED:
      return Win32Window::MessageHandler(hwnd, message, wparam, lparam);

    // Enforced here rather than through window_manager's minimumSize, whose
    // scale factor only updates with the WM_DPICHANGED it no longer receives.
    // Computing it from the window's DPI is correct at every step of a move
    // between monitors.
    case WM_GETMINMAXINFO: {
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      const UINT dpi = FlutterDesktopGetDpiForHWND(hwnd);
      // Frame around the client as sized in WM_NCCALCSIZE above: the default
      // side and bottom borders, with nothing above the client.
      RECT frame = {0, 0, 0, 0};
      AdjustWindowRectExForDpi(&frame, WS_OVERLAPPEDWINDOW, FALSE, 0, dpi);
      info->ptMinTrackSize.x =
          MulDiv(kMinimumClientSize.cx, dpi, USER_DEFAULT_SCREEN_DPI) +
          (frame.right - frame.left);
      info->ptMinTrackSize.y =
          MulDiv(kMinimumClientSize.cy, dpi, USER_DEFAULT_SCREEN_DPI) +
          frame.bottom;
      return 0;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    case WM_STYLECHANGED: {
      if (wparam == GWL_STYLE) {
        const auto* style = reinterpret_cast<STYLESTRUCT*>(lparam);
        // Fullscreen strips WS_OVERLAPPEDWINDOW; round the corners only while
        // the window is still an ordinary framed floating window.
        ApplyWindowCornerPreference(
            hwnd, (style->styleNew & WS_OVERLAPPEDWINDOW) != 0);
        MARGINS margins = {0, 0, 0, 0};
        DwmExtendFrameIntoClientArea(hwnd, &margins);
        SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER |
                         SWP_FRAMECHANGED);
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
