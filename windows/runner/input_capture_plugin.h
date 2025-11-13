#ifndef RUNNER_INPUT_CAPTURE_PLUGIN_H_
#define RUNNER_INPUT_CAPTURE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>

#include <memory>

namespace input_capture {

class InputCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  InputCapturePlugin();
  virtual ~InputCapturePlugin();

  // Disallow copy and assign.
  InputCapturePlugin(const InputCapturePlugin&) = delete;
  InputCapturePlugin& operator=(const InputCapturePlugin&) = delete;

 private:
  // Method channel handler
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Event stream handler
  class EventStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
   public:
    EventStreamHandler(InputCapturePlugin* plugin);

   protected:
    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
        const flutter::EncodableValue* arguments,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;

    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
        const flutter::EncodableValue* arguments) override;

   private:
    InputCapturePlugin* plugin_;
  };

  bool StartCapture();
  void StopCapture();
  bool IsCapturing() const { return is_capturing_; }
  flutter::EncodableMap CheckPermissions() const;
  bool RequestPermissions();

  void SendEvent(const flutter::EncodableMap& event);

  // Hook procedures
  static LRESULT CALLBACK KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam);
  static LRESULT CALLBACK MouseHookProc(int nCode, WPARAM wParam, LPARAM lParam);

  static InputCapturePlugin* instance_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  HHOOK keyboard_hook_;
  HHOOK mouse_hook_;
  bool is_capturing_;
};

}  // namespace input_capture

#endif  // RUNNER_INPUT_CAPTURE_PLUGIN_H_
