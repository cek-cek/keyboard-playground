#include "input_capture_plugin.h"

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace input_capture {

// Static member
InputCapturePlugin* InputCapturePlugin::instance_ = nullptr;

// Helper function to get current timestamp
int64_t GetTimestamp() {
  FILETIME ft;
  GetSystemTimeAsFileTime(&ft);
  ULARGE_INTEGER uli;
  uli.LowPart = ft.dwLowDateTime;
  uli.HighPart = ft.dwHighDateTime;
  // Convert to milliseconds since epoch
  return (uli.QuadPart / 10000) - 11644473600000LL;
}

// Helper function to convert virtual key code to string
std::string VKeyToString(DWORD vkCode) {
  // Printable ASCII characters
  if (vkCode >= 0x30 && vkCode <= 0x39) {  // Numbers 0-9
    return std::string(1, static_cast<char>(vkCode));
  }
  if (vkCode >= 0x41 && vkCode <= 0x5A) {  // Letters A-Z
    return std::string(1, static_cast<char>(vkCode + 32));  // Convert to lowercase
  }

  // Special keys
  switch (vkCode) {
    case VK_RETURN: return "Return";
    case VK_TAB: return "Tab";
    case VK_BACK: return "Backspace";
    case VK_ESCAPE: return "Escape";
    case VK_DELETE: return "Delete";
    case VK_HOME: return "Home";
    case VK_END: return "End";
    case VK_PRIOR: return "PageUp";
    case VK_NEXT: return "PageDown";
    case VK_LEFT: return "Left";
    case VK_RIGHT: return "Right";
    case VK_UP: return "Up";
    case VK_DOWN: return "Down";
    case VK_SPACE: return "Space";
    case VK_F1: return "F1";
    case VK_F2: return "F2";
    case VK_F3: return "F3";
    case VK_F4: return "F4";
    case VK_F5: return "F5";
    case VK_F6: return "F6";
    case VK_F7: return "F7";
    case VK_F8: return "F8";
    case VK_F9: return "F9";
    case VK_F10: return "F10";
    case VK_F11: return "F11";
    case VK_F12: return "F12";
    case VK_SHIFT:
    case VK_LSHIFT:
    case VK_RSHIFT: return "Shift";
    case VK_CONTROL:
    case VK_LCONTROL:
    case VK_RCONTROL: return "Control";
    case VK_MENU:
    case VK_LMENU:
    case VK_RMENU: return "Alt";
    case VK_LWIN:
    case VK_RWIN: return "Meta";
    default:
      return "Key" + std::to_string(vkCode);
  }
}

// Event stream handler implementation
InputCapturePlugin::EventStreamHandler::EventStreamHandler(InputCapturePlugin* plugin)
    : plugin_(plugin) {}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
InputCapturePlugin::EventStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  plugin_->event_sink_ = std::move(events);
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
InputCapturePlugin::EventStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
  plugin_->event_sink_ = nullptr;
  return nullptr;
}

// InputCapturePlugin implementation
InputCapturePlugin::InputCapturePlugin()
    : keyboard_hook_(nullptr),
      mouse_hook_(nullptr),
      is_capturing_(false) {
  instance_ = this;
}

InputCapturePlugin::~InputCapturePlugin() {
  if (is_capturing_) {
    StopCapture();
  }
  instance_ = nullptr;
}

void InputCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<InputCapturePlugin>();

  // Create method channel
  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.keyboardplayground/input_capture",
          &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  plugin->method_channel_ = std::move(method_channel);

  // Create event channel
  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.keyboardplayground/input_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler = std::make_unique<EventStreamHandler>(plugin.get());
  event_channel->SetStreamHandler(std::move(handler));

  plugin->event_channel_ = std::move(event_channel);

  registrar->AddPlugin(std::move(plugin));
}

void InputCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method_name = method_call.method_name();

  if (method_name == "startCapture") {
    bool success = StartCapture();
    result->Success(flutter::EncodableValue(success));
  } else if (method_name == "stopCapture") {
    StopCapture();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "isCapturing") {
    result->Success(flutter::EncodableValue(is_capturing_));
  } else if (method_name == "checkPermissions") {
    result->Success(flutter::EncodableValue(CheckPermissions()));
  } else if (method_name == "requestPermissions") {
    bool success = RequestPermissions();
    result->Success(flutter::EncodableValue(success));
  } else {
    result->NotImplemented();
  }
}

bool InputCapturePlugin::StartCapture() {
  if (is_capturing_) {
    return true;
  }

  // Install keyboard hook
  keyboard_hook_ = SetWindowsHookEx(
      WH_KEYBOARD_LL,
      KeyboardHookProc,
      GetModuleHandle(nullptr),
      0);

  if (!keyboard_hook_) {
    return false;
  }

  // Install mouse hook
  mouse_hook_ = SetWindowsHookEx(
      WH_MOUSE_LL,
      MouseHookProc,
      GetModuleHandle(nullptr),
      0);

  if (!mouse_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
    return false;
  }

  is_capturing_ = true;
  return true;
}

void InputCapturePlugin::StopCapture() {
  if (!is_capturing_) {
    return;
  }

  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }

  if (mouse_hook_) {
    UnhookWindowsHookEx(mouse_hook_);
    mouse_hook_ = nullptr;
  }

  is_capturing_ = false;
}

flutter::EncodableMap InputCapturePlugin::CheckPermissions() const {
  flutter::EncodableMap permissions;
  // On Windows, hooks generally work without special permissions
  // unless running in a protected environment
  permissions[flutter::EncodableValue("hooks")] = flutter::EncodableValue(true);
  return permissions;
}

bool InputCapturePlugin::RequestPermissions() {
  // On Windows, no special permission request is needed
  return true;
}

void InputCapturePlugin::SendEvent(const flutter::EncodableMap& event) {
  if (event_sink_) {
    event_sink_->Success(flutter::EncodableValue(event));
  }
}

LRESULT CALLBACK InputCapturePlugin::KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode >= 0 && instance_ && instance_->event_sink_) {
    KBDLLHOOKSTRUCT* kb = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);

    flutter::EncodableMap event;
    event[flutter::EncodableValue("timestamp")] = flutter::EncodableValue(GetTimestamp());

    bool is_down = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
    event[flutter::EncodableValue("type")] =
        flutter::EncodableValue(is_down ? "keyDown" : "keyUp");

    event[flutter::EncodableValue("keyCode")] =
        flutter::EncodableValue(static_cast<int>(kb->vkCode));

    event[flutter::EncodableValue("key")] =
        flutter::EncodableValue(VKeyToString(kb->vkCode));

    // Get modifier keys state
    flutter::EncodableList modifiers;
    if (GetAsyncKeyState(VK_SHIFT) & 0x8000) {
      modifiers.push_back(flutter::EncodableValue("shift"));
    }
    if (GetAsyncKeyState(VK_CONTROL) & 0x8000) {
      modifiers.push_back(flutter::EncodableValue("control"));
    }
    if (GetAsyncKeyState(VK_MENU) & 0x8000) {
      modifiers.push_back(flutter::EncodableValue("alt"));
    }
    if ((GetAsyncKeyState(VK_LWIN) & 0x8000) || (GetAsyncKeyState(VK_RWIN) & 0x8000)) {
      modifiers.push_back(flutter::EncodableValue("meta"));
    }
    event[flutter::EncodableValue("modifiers")] = flutter::EncodableValue(modifiers);

    instance_->SendEvent(event);

    // Return -1 to prevent the event from being passed to the rest of the hook chain
    // This creates the "sandbox" behavior
    return -1;
  }

  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

LRESULT CALLBACK InputCapturePlugin::MouseHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode >= 0 && instance_ && instance_->event_sink_) {
    MSLLHOOKSTRUCT* ms = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);

    flutter::EncodableMap event;
    event[flutter::EncodableValue("timestamp")] = flutter::EncodableValue(GetTimestamp());

    switch (wParam) {
      case WM_MOUSEMOVE:
        event[flutter::EncodableValue("type")] = flutter::EncodableValue("mouseMove");
        event[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.x));
        event[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.y));
        break;

      case WM_LBUTTONDOWN:
      case WM_LBUTTONUP:
        event[flutter::EncodableValue("type")] =
            flutter::EncodableValue(wParam == WM_LBUTTONDOWN ? "mouseDown" : "mouseUp");
        event[flutter::EncodableValue("button")] = flutter::EncodableValue("left");
        event[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.x));
        event[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.y));
        break;

      case WM_RBUTTONDOWN:
      case WM_RBUTTONUP:
        event[flutter::EncodableValue("type")] =
            flutter::EncodableValue(wParam == WM_RBUTTONDOWN ? "mouseDown" : "mouseUp");
        event[flutter::EncodableValue("button")] = flutter::EncodableValue("right");
        event[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.x));
        event[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.y));
        break;

      case WM_MBUTTONDOWN:
      case WM_MBUTTONUP:
        event[flutter::EncodableValue("type")] =
            flutter::EncodableValue(wParam == WM_MBUTTONDOWN ? "mouseDown" : "mouseUp");
        event[flutter::EncodableValue("button")] = flutter::EncodableValue("middle");
        event[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.x));
        event[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(ms->pt.y));
        break;

      case WM_MOUSEWHEEL:
      case WM_MOUSEHWHEEL: {
        event[flutter::EncodableValue("type")] = flutter::EncodableValue("mouseScroll");
        short delta = static_cast<short>(HIWORD(ms->mouseData));
        double normalized_delta = delta / 120.0;  // WHEEL_DELTA is 120

        if (wParam == WM_MOUSEWHEEL) {
          event[flutter::EncodableValue("deltaX")] = flutter::EncodableValue(0.0);
          event[flutter::EncodableValue("deltaY")] = flutter::EncodableValue(normalized_delta);
        } else {
          event[flutter::EncodableValue("deltaX")] = flutter::EncodableValue(normalized_delta);
          event[flutter::EncodableValue("deltaY")] = flutter::EncodableValue(0.0);
        }
        break;
      }

      default:
        // Unknown event type, don't send
        return CallNextHookEx(nullptr, nCode, wParam, lParam);
    }

    instance_->SendEvent(event);

    // Return 1 to prevent the event from being passed to the rest of the hook chain (per Windows API documentation)
    return 1;
  }

  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

}  // namespace input_capture
