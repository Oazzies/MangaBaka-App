#include "flutter_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Win11 leaves an extended-frame window square unless asked. Defined here for
// pre-Win11 SDKs; older Windows rejects the attribute as a harmless no-op.
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
constexpr int kDwmcpRound = 2;
constexpr int kDwmcpDoNotRound = 1;

void ApplyWindowCornerPreference(HWND window, bool rounded) {
  int preference = rounded ? kDwmcpRound : kDwmcpDoNotRound;
  DwmSetWindowAttribute(window, DWMWA_WINDOW_CORNER_PREFERENCE, &preference,
                        sizeof(preference));
}

// Logical px; the width must stay equal to DesktopLayout.minWidth.
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

  // Must match the window size, or startup recreates the surface.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // The first frame can land before the show callback is registered.
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
  // window_manager insets by a fixed 8px but the border is DPI dependent (~11px
  // at 150%), so floating windows keep the default frame minus the caption.
  // Never swallow WM_NCPAINT: DWM then shows the unpainted border as stale pixels.
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
    // Kept from window_manager: its 1px "refresh" resize blocks a frame each
    // way and doubled the freeze at every monitor crossing.
    case WM_DPICHANGED:
      return Win32Window::MessageHandler(hwnd, message, wparam, lparam);

    // Not window_manager's minimumSize: its scale only updates on WM_DPICHANGED.
    case WM_GETMINMAXINFO: {
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      const UINT dpi = FlutterDesktopGetDpiForHWND(hwnd);
      // As sized in WM_NCCALCSIZE: side and bottom borders, nothing on top.
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
        // Fullscreen strips the frame; square there so nothing clips at the edge.
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
